if test -f ~/.keys/deepinfa-key
    export DEEPINFRA_API_KEY=$(cat ~/.keys/deepinfa-key)
end
if test -f ~/.keys/xai-api-key
    export XAI_API_KEY=$(cat ~/.keys/xai-api-key)
end
if test -f ~/.keys/groq-api-key
    export GROQ_API_KEY=$(cat ~/.keys/groq-api-key)
end
if test -f ~/.keys/deepseek-api-key
    export DEEPSEEK_API_KEY=$(cat ~/.keys/deepseek-api-key)
end
if test -f ~/.keys/googleai-api-key
    export GOOGLE_AI_API_KEY=$(cat ~/.keys/googleai-api-key)
end
if test -f ~/.keys/anthropic-api-key
    export ANTHROPIC_API_KEY=$(cat ~/.keys/anthropic-api-key)
end
