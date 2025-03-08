
async function testOdosApi() {
  const quoteUrl = 'https://api.odos.xyz/sor/quote/v2';
  const quoteRequestBody = {
    chainId: 8453, // Base chain ID
    inputTokens: [
      {
        tokenAddress: '0x4200000000000000000000000000000000000006', // checksummed input token address
        amount: '100000', // input amount as a string in fixed integer precision
      }
    ],
    outputTokens: [
      {
        tokenAddress: '0x007bb7a4bfc214DF06474E39142288E99540f2b3', // checksummed output token address
        proportion: 1
      }
    ],
    userAddr: '0x897Ec8F290331cfb0916F57b064e0A78Eab0e4A5', // checksummed user address (replace with actual user address)
    slippageLimitPercent: 2, // set your slippage limit percentage (1 = 1%),
    referralCode: 0, // referral code (recommended)
    disableRFQs: true,
    compact: true,
  };

  try {
    const response = await fetch(
      quoteUrl,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(quoteRequestBody),
      }
    );

    if (response.status === 200) {
      const quote = await response.json();
      console.log('Quote Response:', quote);
      // handle quote response data
    } else {
      console.error('Error in Quote:', response.status, response.statusText);
      // handle quote failure cases
    }
  } catch (error) {
    console.error('Error in API call:', error);
  }
}

testOdosApi();
