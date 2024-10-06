# Private AI for Solana

![SoloBot](llamaUI/Assets.xcassets/SoloBot.jpg "Private AI Solana Bot")

Sample project for the hackathon Solana Radar 2024

This project tries to create a desktop app that can connect to a Solana endpoint, obtain data and process it with an LLM to get information from it.

Currently, it connects to Coinmarketcap. To run this example, it requires an API key from Coinmarketcap. You must update the constant "COIN_MARKET_CAP_API", it does not compile without it. Get it here: https://pro.coinmarketcap.com/signup/

Also, it requires to download an LLM Model. It was tested with
https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/

A fork of project: https://github.com/rhvall/llamaCPP-xcode
