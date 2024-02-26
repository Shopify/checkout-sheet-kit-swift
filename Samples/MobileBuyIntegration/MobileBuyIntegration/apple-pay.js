const MINIMUM_APPLE_PAY_VERSION = 6;

function getPartnerSDKEligibility() {
  if (typeof window === "undefined" || window.ApplePaySession === undefined) {
    return {
      eligible: false,
      reason: "window or ApplePaySession is undefined",
    };
  }

  if (!window.ApplePaySession.supportsVersion?.(MINIMUM_APPLE_PAY_VERSION)) {
    return {
      eligible: false,
      reason: "SDK does not meet minimum version requirement",
    };
  }

  if (!window.ApplePaySession.canMakePayments?.()) {
    return {
      eligible: false,
      reason: "failed SDK eligibility check",
    };
  }
  return {
    eligible: true,
  };
}

export function pay() {
  const eligibility = getPartnerSDKEligibility();

  if (!eligibility.eligible) {
    console.error("Apple Pay is not eligible", eligibility.reason);
    return;
  }

  var request = {
    countryCode: "US",
    currencyCode: "USD",
    supportedNetworks: ["visa", "masterCard", "amex", "discover"],
    merchantCapabilities: ["supports3DS"],
    total: { label: "MobileBuy SDK test", amount: "10.00" },
  };
  var session = new ApplePaySession(3, request);

  session.onvalidatemerchant = function (event) {
    session.completeMerchantValidation(true);
  };
}
