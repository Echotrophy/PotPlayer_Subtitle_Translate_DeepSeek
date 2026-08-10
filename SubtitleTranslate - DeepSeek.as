string GetTitle() {
    return "{$CP936=DeepSeek 翻译$}{$CP0=DeepSeek Translate$}";
}

string GetVersion() {
    return "2.2";
}

string GetDesc() {
    return "{$CP936=使用 DeepSeek V4 的实时字幕翻译$}{$CP0=Real-time subtitle translation using DeepSeek V4 API$}";
}

string GetLoginTitle() {
    return "{$CP936=DeepSeek 模型与 API 密钥配置$}{$CP0=DeepSeek Model + API URL and API Key Configuration$}";
}

string GetLoginDesc() {
    return "{$CP936=请输入模型名称和 API 地址，以及 API 密钥（例如: deepseek-v4-flash|https://api.deepseek.com）$}{$CP0=Please enter the model name + API URL and provide the API Key (e.g., deepseek-v4-flash|https://api.deepseek.com)$}";
}

string GetUserText() {
    return "{$CP936=模型名称|API 地址 (当前: " + selected_model + " | " + apiUrl + ")$}{$CP0=Model Name|API URL (Current: " + selected_model + " | " + apiUrl + ")$}";
}

string GetPasswordText() {
    return "{$CP936=API 密钥:$}{$CP0=API Key:$}";
}

string api_key = "";
string selected_model = "deepseek-v4-flash";
string apiUrl = "https://api.deepseek.com/chat/completions";
string UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)";

string BuildFullUrl(const string &in base) {
    string url = base.Trim();
    if (url.find("chat/completions") != -1) {
        return url;
    }
    if (url.substr(url.length() - 1) == "/") {
        url = url.substr(0, url.length() - 1);
    }
    return url + "/chat/completions";
}

array<string> LangTable =
{
    "zh-CN", "zh-TW", "en", "ja", "ko", "af", "sq", "am", "ar", "hy", "az", "eu", "be", "bn", "bs", "bg", "ca",
    "ceb", "ny", "co", "hr", "cs", "da", "nl", "eo", "et", "tl", "fi", "fr",
    "fy", "gl", "ka", "de", "el", "gu", "ht", "ha", "haw", "he", "hi", "hmn", "hu", "is", "ig", "id", "ga", "it", "jw", "kn", "kk", "km",
    "ku", "ky", "lo", "la", "lv", "lt", "lb", "mk", "ms", "mg", "ml", "mt", "mi", "mr", "mn", "my", "ne", "no", "ps", "fa", "pl", "pt",
    "pa", "ro", "ru", "sm", "gd", "sr", "st", "sn", "sd", "si", "sk", "sl", "so", "es", "su", "sw", "sv", "tg", "ta", "te", "th", "tr", "uk",
    "ur", "uz", "vi", "cy", "xh", "yi", "yo", "zu"
};

array<string> GetSrcLangs() {
    array<string> ret = LangTable;
    ret.insertAt(0, "");
    return ret;
}

array<string> GetDstLangs() {
    array<string> ret = LangTable;
    return ret;
}

string ServerLogin(string User, string Pass) {
    User = User.Trim();
    Pass = Pass.Trim();

    string userModel = "";
    string customApiUrl = "";

    int sepPos = User.find("|");
    if (sepPos != -1) {
        userModel = User.substr(0, sepPos).Trim();
        customApiUrl = User.substr(sepPos + 1).Trim();
    } else if (User.find("http") == 0) {
        customApiUrl = User;
    } else {
        userModel = User;
    }

    if (userModel.empty()) {
        userModel = "deepseek-v4-flash";
    }
    if (customApiUrl.empty()) {
        customApiUrl = "https://api.deepseek.com";
    }

    if (Pass.empty()) {
        HostPrintUTF8("{$CP0=API Key not configured. Please enter a valid API Key.$}{$CP936=未输入 API 密钥，请输入有效的 API 密钥。$}\n");
        return "fail: API Key is empty";
    }

    selected_model = userModel;
    api_key = Pass;
    apiUrl = BuildFullUrl(customApiUrl);

    HostSaveString("api_key", api_key);
    HostSaveString("selected_model", selected_model);
    HostSaveString("apiUrl", apiUrl);

    HostPrintUTF8("{$CP0=API Key and model name successfully configured. Full URL: $}{$CP936=API 密钥和模型名称配置成功。完整 URL: $}" + apiUrl + "\n");
    return "200 ok";
}

void ServerLogout() {
    api_key = "";
    selected_model = "deepseek-v4-flash";
    apiUrl = "https://api.deepseek.com/chat/completions";
    subtitleHistory.resize(0);
    HostSaveString("api_key", "");
    HostSaveString("selected_model", selected_model);
    HostSaveString("apiUrl", apiUrl);
    HostPrintUTF8("{$CP0=Successfully logged out.$}{$CP936=已成功注销。$}\n");
}

string JsonEscape(const string &in input) {
    string output = input;
    output.replace("\\", "\\\\");
    output.replace("\"", "\\\"");
    output.replace("\n", "\\n");
    output.replace("\r", "\\r");
    output.replace("\t", "\\t");
    return output;
}

array<string> subtitleHistory;
string UNICODE_RLE = "\u202B";

int EstimateTokenCount(const string &in text) {
    return int(float(text.length()) / 4);
}

int GetModelMaxTokens(const string &in modelName) {
    if (modelName.find("deepseek-v4") == 0) {
        return 16000;
    }
    return 4096;
}

string Translate(string Text, string &in SrcLang, string &in DstLang) {
    api_key = HostLoadString("api_key", "");
    selected_model = HostLoadString("selected_model", "deepseek-v4-flash");
    apiUrl = HostLoadString("apiUrl", "https://api.deepseek.com/chat/completions");

    if (selected_model == "deepseek-chat" || selected_model == "deepseek-reasoner") {
        selected_model = "deepseek-v4-flash";
        HostSaveString("selected_model", selected_model);
    }

    if (apiUrl.find("chat/completions") == -1) {
        apiUrl = BuildFullUrl(apiUrl);
    }

    if (api_key.empty()) {
        HostPrintUTF8("{$CP0=API Key not configured. Please enter it in the settings menu.$}{$CP936=未配置 API 密钥，请在设置菜单中输入。$}\n");
        return "翻译失败: 未配置 API Key，请到 账户设置 中填写";
    }

    if (DstLang.empty()) {
        HostPrintUTF8("{$CP0=Target language not specified. Please select a target language.$}{$CP936=未选择目标语言，请选择目标语言。$}\n");
        return "翻译失败: 未选择目标语言";
    }

    if (SrcLang.empty() || SrcLang == "Auto Detect") {
        SrcLang = "";
    }

    subtitleHistory.insertLast(Text);

    int maxTokens = GetModelMaxTokens(selected_model);

    string context = "";
    int tokenCount = EstimateTokenCount(Text);
    int i = int(subtitleHistory.length()) - 2;
    while (i >= 0 && tokenCount < (maxTokens - 1000)) {
        string subtitle = subtitleHistory[i];
        int subtitleTokens = EstimateTokenCount(subtitle);
        tokenCount += subtitleTokens;
        if (tokenCount < (maxTokens - 1000)) {
            context = subtitle + "\n" + context;
        }
        i--;
    }

    if (subtitleHistory.length() > 50) {
        subtitleHistory.removeAt(0);
    }

    string prompt = "You are a professional translator. Please translate the following subtitle, output only translated results. If content that violates the Terms of Service appears, just output the translation result that complies with safety standards.";
    if (!SrcLang.empty()) {
        prompt += " from " + SrcLang;
    }
    prompt += " to " + DstLang + ". Use the context provided to maintain coherence.\n";
    if (!context.empty()) {
        prompt += "Context:\n" + context + "\n";
    }
    prompt += "Subtitle to translate:\n" + Text;

    string escapedPrompt = JsonEscape(prompt);

    string requestData = "{\"model\":\"" + selected_model + "\","
                         "\"messages\":[{\"role\":\"user\",\"content\":\"" + escapedPrompt + "\"}],"
                         "\"max_tokens\":1000,\"temperature\":0";
    if (apiUrl.find("deepseek.com") != -1) {
        requestData += ",\"thinking\":{\"type\":\"disabled\"}";
    }
    requestData += "}";

    string headers = "Content-Type: application/json\r\nAuthorization: Bearer " + api_key;

    HostIncTimeOut(15000);

    int httpStatus = 0;
    string response = "";
    uintptr http = HostOpenHTTP(apiUrl, UserAgent, headers, requestData);
    if (http != 0) {
        httpStatus = HostGetStatusHTTP(http);
        response = HostGetContentHTTP(http);
        HostCloseHTTP(http);
    }

    if (httpStatus != 200) {
        string errMsg = "翻译失败: HTTP " + httpStatus;
        if (response.length() > 0) {
            errMsg += " - " + response;
        }
        HostPrintUTF8("{$CP0=HTTP Error: $}{$CP936=HTTP 错误: $}" + httpStatus + " : " + response + "\n");
        return errMsg;
    }

    if (response.empty()) {
        HostPrintUTF8("{$CP0=Translation request failed. Please check network connection or API Key.$}{$CP936=翻译请求失败（超时或无响应），请检查网络连接或 API 密钥。$}\n");
        return "翻译失败: 请求无响应（可能超时），请检查网络";
    }

    JsonReader Reader;
    JsonValue Root;
    if (!Reader.parse(response, Root)) {
        HostPrintUTF8("{$CP0=Failed to parse API response.$}{$CP936=解析 API 响应失败。$}\n" + response + "\n");
        return "翻译失败: API 响应解析失败";
    }

    if (!Root["error"].isNull() && Root["error"]["message"].isString()) {
        string errorMessage = Root["error"]["message"].asString();
        HostPrintUTF8("{$CP0=API Error: $}{$CP936=API 错误: $}" + errorMessage + "\n");
        return "翻译失败: " + errorMessage;
    }

    JsonValue choices = Root["choices"];
    if (choices.isArray() && choices.size() > 0) {
        string translatedText = "";
        if (choices[0]["message"]["content"].isString()) {
            translatedText = choices[0]["message"]["content"].asString();
        }

        if (translatedText.empty() && choices[0]["message"]["reasoning_content"].isString()) {
            translatedText = choices[0]["message"]["reasoning_content"].asString();
        }

        translatedText = translatedText.Trim();
        if (translatedText.find("\n") != -1) {
            array<string> lines = translatedText.split("\n");
            translatedText = lines[lines.length() - 1].Trim();
        }

        if (DstLang == "fa" || DstLang == "ar" || DstLang == "he") {
            translatedText = UNICODE_RLE + translatedText;
        }

        SrcLang = "UTF8";
        DstLang = "UTF8";
        return translatedText;
    }

    HostPrintUTF8("{$CP0=Translation failed. Please check input parameters or API Key configuration.$}{$CP936=翻译失败，请检查输入参数或 API 密钥配置。$}\n");
    return "翻译失败: API 返回中没有有效内容";
}

void OnInitialize() {
    HostPrintUTF8("{$CP0=DeepSeek V4 translation plugin loaded.$}{$CP936=DeepSeek V4 翻译插件已加载。$}\n");
    api_key = HostLoadString("api_key", "");
    selected_model = HostLoadString("selected_model", "deepseek-v4-flash");
    apiUrl = HostLoadString("apiUrl", "https://api.deepseek.com/chat/completions");

    if (selected_model == "deepseek-chat" || selected_model == "deepseek-reasoner") {
        selected_model = "deepseek-v4-flash";
        HostSaveString("selected_model", selected_model);
    }

    if (!api_key.empty()) {
        HostPrintUTF8("{$CP0=Saved API Key, model name, and API URL loaded.$}{$CP936=已加载保存的 API 密钥、模型名称和 API 地址。$}\n");
    }
    subtitleHistory.resize(0);
}

void OnFinalize() {
    HostPrintUTF8("{$CP0=DeepSeek V4 translation plugin unloaded.$}{$CP936=DeepSeek V4 翻译插件已卸载。$}\n");
}
