# Byteform

Running tests:

    forge test

Running build:

    forge build

## Generating the font

### Download base font file from EthFS

To download the IBMPlexMono-Regular.woff2 font file from EthFS on Ethereum mainnet:

    forge script script/DownloadFont.s.sol:DownloadFontScript \
        --rpc-url $RPC_URL_MAINNET \
        --chain-id 1

Make sure you have `RPC_URL_MAINNET` set in your `.env` file or environment variables.

### Generate smaller subset file

    pyftsubset assets/IBMPlexMono-Regular.woff2 \
        --unicodes=U+0000-007F \
        --output-file=assets/IBMPlexMono-7Bit-ASCII.woff2 \
        --flavor=woff2
