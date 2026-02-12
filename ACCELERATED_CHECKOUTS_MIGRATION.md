# AcceleratedCheckouts Migration to CheckoutCommunicationProtocol

## Status
AcceleratedCheckouts targets are temporarily disabled in `Package.swift` while the core SDK migrates to the UCP bridge handler pattern.

## What Changed

### Removed Types
| Type | Replacement |
|------|-------------|
| `CheckoutDelegate` protocol | `CheckoutCommunicationProtocol` protocol (raw string in/out) |
| `CheckoutCompletedEvent` | Protocol library's `Checkout` model via `CheckoutProtocol.Handler` |
| `PixelEvent`, `StandardEvent`, `CustomEvent` | Handled by protocol event subscriptions |
| `CheckoutDelegateWrapper` | `CheckoutSheet.onCancel()` / `.onFail()` closures + `.connect(handler)` |
| `CheckoutCompletedEventDecoder` | Protocol library's `CheckoutProtocol.decode()` |
| `WebPixelsEventDecoder` | Protocol library's event handling |
| `DecodeDictionary` | No longer needed |
| `CheckoutError.configurationError` | Handled by protocol events |

### New Types
| Type | Purpose |
|------|---------|
| `CheckoutCommunicationProtocol` protocol | `readyMessage: String?` + `handleMessage(_:) async -> String?` |
| `CheckoutBridge.sendProtocolMessage(_:_:)` | Sends JSON-RPC responses back to webview via `postMessage` |

### API Changes
| Before | After |
|--------|-------|
| `CheckoutViewController(checkout:delegate:)` | `CheckoutViewController(checkout:bridgeHandler:)` |
| `CheckoutSheet.onComplete(_:)` | `CheckoutProtocol.Handler().on(.complete) { ... }` via `.connect()` |
| `CheckoutSheet.onPixelEvent(_:)` | Protocol event subscriptions |
| `CheckoutSheet.onLinkClick(_:)` | Handled internally by SDK (opens URL) |
| `present(checkout:from:delegate:)` | `present(checkout:from:bridgeHandler:)` |

## Migration Steps for AcceleratedCheckouts

### 1. WalletController
`WalletController.present(url:delegate:)` needs to accept `CheckoutCommunicationProtocol` instead of `CheckoutDelegate`:
```swift
// Before
func present(url: URL, delegate: CheckoutDelegate) async throws
// After
func present(url: URL, bridgeHandler: (any CheckoutCommunicationProtocol)?) async throws
```

### 2. ShopPayViewController
Remove `CheckoutDelegate` conformance. Instead, create a `CheckoutProtocol.Handler` and pass it via `bridgeHandler`:
```swift
// The ShopPayViewController should create and configure a protocol handler
// that forwards events to its own callbacks
```

### 3. ApplePayViewController
Same as ShopPayViewController — replace `CheckoutDelegate` conformance with protocol handler setup.

### 4. Wallet Event Handlers
`Wallet.EventHandlers` currently stores closures typed to `CheckoutCompletedEvent` and `PixelEvent`. These need to be updated to use protocol library types or generic closures.

### 5. AcceleratedCheckoutButtons
`.onComplete()` and `.onWebPixelEvent()` modifiers need to be reworked to use the protocol handler pattern.

### 6. Re-enable in Package.swift
After migration, uncomment the AcceleratedCheckouts targets in `Package.swift` and add `ShopifyCheckoutProtocol` as a dependency for the AcceleratedCheckouts target.

## Unresolved Aspects

### Modal Toggling
The old `checkoutBlockingEvent` / `checkoutViewDidToggleModal` mechanism has no equivalent in the UCP protocol yet. The navigation bar hide/show behavior is not available in the prototype.

### Recovery Mode Completion
In recovery mode (bridge disabled), checkout completion detection via URL observation no longer fires a callback to the host app. The cache is invalidated but no completion event is emitted. This needs a solution for production.
