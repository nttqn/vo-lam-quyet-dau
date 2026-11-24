// VLStoreKit: StoreKit (1) in-app purchases for iOS as a GDExtension.
//
// Engine singleton "VLStoreKit" (scripts/iap.gd uses it). Everything StoreKit
// reports is queued as a Dictionary event; the "event" signal says there is
// something new and take_events() drains the queue. The queue also holds what
// arrives before any script listens (unfinished transactions replayed at launch).
//
// Events (key "type"):
//   products        items: [{id, price, title}], invalid: [ids]
//   products_error  msg
//   purchased       id, tid        -> grant, then finish(tid)
//   restored        id, tid        -> grant, then finish(tid)
//   failed          id, code, msg, cancelled   (already finished here)
//   deferred        id             (Ask to Buy: waits for a parent)
//   restore_done
//   restore_failed  code, msg
//
// Built by build.sh on the iOS CI runner only (static library in an xcframework).

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>

// static library: tell the app's linker to pull these frameworks in
__asm__(".linker_option \"-framework\", \"StoreKit\"");
__asm__(".linker_option \"-framework\", \"Foundation\"");

using namespace godot;

static String to_godot(NSString *s) {
	return s == nil ? String() : String::utf8([s UTF8String]);
}

static NSString *to_ns(const String &s) {
	return [NSString stringWithUTF8String:s.utf8().get_data()];
}

class VLStoreKit : public Object {
	GDCLASS(VLStoreKit, Object);

	Array events;

protected:
	static void _bind_methods();

public:
	static VLStoreKit *singleton;

	void push(const Dictionary &e) {
		events.push_back(e);
		call_deferred("emit_signal", "event");
	}

	bool can_pay();
	void request_products(const PackedStringArray &ids);
	void purchase(const String &id);
	void restore();
	void finish(const String &tid);

	Array take_events() {
		Array out = events;
		events = Array();
		return out;
	}
};

VLStoreKit *VLStoreKit::singleton = nullptr;

// ---------------------------------------------------------------- observer
@interface VLSKObserver : NSObject <SKPaymentTransactionObserver, SKProductsRequestDelegate>
@property(nonatomic, strong) NSMutableDictionary<NSString *, SKProduct *> *products;
@property(nonatomic, strong) NSMutableDictionary<NSString *, SKPaymentTransaction *> *open;
@property(nonatomic, strong) NSMutableSet<SKProductsRequest *> *requests;
@end

@implementation VLSKObserver

- (instancetype)init {
	if ((self = [super init])) {
		_products = [NSMutableDictionary dictionary];
		_open = [NSMutableDictionary dictionary];
		_requests = [NSMutableSet set];
	}
	return self;
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	Array items;
	for (SKProduct *p in response.products) {
		self.products[p.productIdentifier] = p;
		NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
		f.numberStyle = NSNumberFormatterCurrencyStyle;
		f.locale = p.priceLocale;
		Dictionary d;
		d["id"] = to_godot(p.productIdentifier);
		d["price"] = to_godot([f stringFromNumber:p.price]);
		d["title"] = to_godot(p.localizedTitle);
		items.push_back(d);
	}
	Array invalid;
	for (NSString *s in response.invalidProductIdentifiers) {
		invalid.push_back(to_godot(s));
	}
	Dictionary e;
	e["type"] = "products";
	e["items"] = items;
	e["invalid"] = invalid;
	if (VLStoreKit::singleton) {
		VLStoreKit::singleton->push(e);
	}
}

- (void)requestDidFinish:(SKRequest *)request {
	if ([request isKindOfClass:[SKProductsRequest class]]) {
		[self.requests removeObject:(SKProductsRequest *)request];
	}
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
	if ([request isKindOfClass:[SKProductsRequest class]]) {
		[self.requests removeObject:(SKProductsRequest *)request];
	}
	Dictionary e;
	e["type"] = "products_error";
	e["msg"] = to_godot(error.localizedDescription);
	if (VLStoreKit::singleton) {
		VLStoreKit::singleton->push(e);
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
	for (SKPaymentTransaction *t in transactions) {
		Dictionary e;
		e["id"] = to_godot(t.payment.productIdentifier);
		switch (t.transactionState) {
			case SKPaymentTransactionStatePurchased:
			case SKPaymentTransactionStateRestored: {
				NSString *tid = t.transactionIdentifier ?: [[NSUUID UUID] UUIDString];
				self.open[tid] = t;
				e["type"] = t.transactionState == SKPaymentTransactionStatePurchased ? "purchased" : "restored";
				e["tid"] = to_godot(tid);
			} break;
			case SKPaymentTransactionStateFailed: {
				e["type"] = "failed";
				e["code"] = (int64_t)t.error.code;
				e["msg"] = to_godot(t.error.localizedDescription);
				e["cancelled"] = [t.error.domain isEqualToString:SKErrorDomain] && t.error.code == SKErrorPaymentCancelled;
				[queue finishTransaction:t];
			} break;
			case SKPaymentTransactionStateDeferred:
				e["type"] = "deferred";
				break;
			default:
				continue; // Purchasing: the system sheet is up
		}
		if (VLStoreKit::singleton) {
			VLStoreKit::singleton->push(e);
		}
	}
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
	Dictionary e;
	e["type"] = "restore_done";
	if (VLStoreKit::singleton) {
		VLStoreKit::singleton->push(e);
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
	Dictionary e;
	e["type"] = "restore_failed";
	e["code"] = (int64_t)error.code;
	e["msg"] = to_godot(error.localizedDescription);
	if (VLStoreKit::singleton) {
		VLStoreKit::singleton->push(e);
	}
}

@end

static VLSKObserver *observer = nil;

// ---------------------------------------------------------------- methods
bool VLStoreKit::can_pay() {
	return [SKPaymentQueue canMakePayments];
}

void VLStoreKit::request_products(const PackedStringArray &ids) {
	NSMutableSet<NSString *> *set = [NSMutableSet set];
	for (int i = 0; i < ids.size(); i++) {
		[set addObject:to_ns(ids[i])];
	}
	SKProductsRequest *r = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
	r.delegate = observer;
	[observer.requests addObject:r];
	[r start];
}

void VLStoreKit::purchase(const String &id) {
	SKProduct *p = observer.products[to_ns(id)];
	if (p == nil) {
		Dictionary e;
		e["type"] = "failed";
		e["id"] = id;
		e["code"] = (int64_t)-1;
		e["msg"] = "product not loaded";
		e["cancelled"] = false;
		push(e);
		return;
	}
	[[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProduct:p]];
}

void VLStoreKit::restore() {
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

void VLStoreKit::finish(const String &tid) {
	NSString *k = to_ns(tid);
	SKPaymentTransaction *t = observer.open[k];
	if (t != nil) {
		[[SKPaymentQueue defaultQueue] finishTransaction:t];
		[observer.open removeObjectForKey:k];
	}
}

void VLStoreKit::_bind_methods() {
	ClassDB::bind_method(D_METHOD("can_pay"), &VLStoreKit::can_pay);
	ClassDB::bind_method(D_METHOD("request_products", "ids"), &VLStoreKit::request_products);
	ClassDB::bind_method(D_METHOD("purchase", "id"), &VLStoreKit::purchase);
	ClassDB::bind_method(D_METHOD("restore"), &VLStoreKit::restore);
	ClassDB::bind_method(D_METHOD("finish", "tid"), &VLStoreKit::finish);
	ClassDB::bind_method(D_METHOD("take_events"), &VLStoreKit::take_events);
	ADD_SIGNAL(MethodInfo("event"));
}

// ---------------------------------------------------------------- module
static void initialize_vl_storekit(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	GDREGISTER_CLASS(VLStoreKit);
	VLStoreKit::singleton = memnew(VLStoreKit);
	Engine::get_singleton()->register_singleton("VLStoreKit", VLStoreKit::singleton);
	observer = [[VLSKObserver alloc] init];
	[[SKPaymentQueue defaultQueue] addTransactionObserver:observer];
}

static void uninitialize_vl_storekit(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	if (observer != nil) {
		[[SKPaymentQueue defaultQueue] removeTransactionObserver:observer];
		observer = nil;
	}
	Engine::get_singleton()->unregister_singleton("VLStoreKit");
	memdelete(VLStoreKit::singleton);
	VLStoreKit::singleton = nullptr;
}

extern "C" {
GDExtensionBool GDE_EXPORT vl_storekit_init(GDExtensionInterfaceGetProcAddress p_get_proc_address,
		const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
	init_obj.register_initializer(initialize_vl_storekit);
	init_obj.register_terminator(uninitialize_vl_storekit);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
	return init_obj.init();
}
}
