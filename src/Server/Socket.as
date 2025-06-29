

// updated 2024-05-19 for new openplanet socket

class BetterSocket {
    Net::Socket@ s;
    bool IsConnecting = false;
    string addr;
    uint16 port;

    BetterSocket(const string &in addr, uint16 port) {
        this.addr = addr;
        this.port = port;
    }

    bool ReconnectToServer() {
        if (s !is null) {
            dev_trace('closing');
            s.Close();
            @s = null;
        }
        Connect();
        return IsUnclosed;
    }

    void StartConnect() {
        IsConnecting = true;
        startnew(CoroutineFunc(Connect));
    }

    void Connect() {
        IsConnecting = true;
        if (s !is null) {
            warn("already have a socket");
            IsConnecting = false;
            return;
        }
        Net::Socket@ socket = Net::Socket();
        if (!socket.Connect(addr, port)) {
            warn("Failed to connect to " + addr + ":" + port);
        } else {
            @s = socket;
            auto timeout = Time::Now + 8000;
            while (s !is null && !s.IsReady() && Time::Now < timeout) yield();
            if (s is null) return;
            if (!s.IsReady()) {
                warn("Failed to connect to " + addr + ":" + port + " in time");
                startnew(CoroutineFunc(StartConnect));
            }
        }
        IsConnecting = false;
    }

    void Shutdown() {
        if (s !is null) {
            trace('Shutdown:closing');
            s.Close();
            @s = null;
        }
    }

    bool get_IsClosed() {
        return s is null || s.IsHungUp();
    }

    bool get_IsUnclosed() {
        return s !is null && !s.IsHungUp();
    }

    protected bool hasWaitingAvailable = false;

    bool get_ServerDisconnected() {
        if (s is null) {
            return true;
        }
        if (s.IsHungUp()) return true;
        return false;
    }

    bool get_HasNewDataToRead() {
        if (hasWaitingAvailable) {
            hasWaitingAvailable = false;
            return true;
        }
        return s !is null && s.Available() > 0;
    }

    int get_Available() {
        return s !is null ? s.Available() : 0;
    }

    // true if last message was received more than 1 minute ago
    bool get_LastMsgRecievedLongAgo() {
        return Time::Now - lastMessageRecvTime > 40000;
    }

    protected RawMessage tmpBuf;
    uint lastMessageRecvTime = 0;

    // parse msg immediately
    RawMessage@ ReadMsg(int timeout = 40000) {
        // read msg length
        // read msg data
        uint startReadTime = Time::Now;
        while (Available < 4 && !IsClosed && !ServerDisconnected && (timeout <= 0 || Time::Now - startReadTime < uint(timeout))) yield();
        if (timeout > 0 && Time::Now - startReadTime >= uint(timeout)) {
            yield();
            yield();
            yield();
            if (Available < 4 && !IsClosed && !ServerDisconnected) {
                warn("ReadMsg timed out while waiting for length");
                warn("Disconnecting socket");
                Shutdown();
                return null;
            }
        }
        if (IsClosed || ServerDisconnected) {
            return null;
        }
        // wait for length
        uint len = s.ReadUint32();
        if (len > ONE_MEGABYTE) {
            error("Message too large: " + len + " bytes, max: 1 MB");
            warn("Disconnecting socket");
            Shutdown();
            return null;
        }

        startReadTime = Time::Now;
        while (Available < int(len)) {
            if (timeout > 0 && Time::Now - startReadTime >= uint(timeout)) {
                yield();
                yield();
                yield();
                if (Available < int(len)) {
                    warn("ReadMsg timed out while reading msg; Available: " + Available + '; len: ' + len);
                    warn("Disconnecting socket");
                    Shutdown();
                    return null;
                }
            }
            if (IsClosed || ServerDisconnected) {
                return null;
            }
            yield();
        }

        tmpBuf.ReadFromSocket(s, len);
        lastMessageRecvTime = Time::Now;
        return tmpBuf;
    }

    void WriteMsg(uint8 msgType, const string &in msgData) {
        if (s is null) {
            if (msgType != uint8(MessageResponseTypes::Ping))
                dev_trace("WriteMsg: dropping msg b/c socket closed/disconnected");
            return;
        }
        bool success = true;
        success = s.Write(uint(5 + msgData.Length)) && success;
        // yield();
        success = s.Write(msgType) && success;
        // yield();
        success = s.Write(msgData) && success;
        if (!success) {
            warn("failure to write message? " + tostring(MessageRequestTypes(msgType)) + " / " + msgData.Length + " bytes");
            // this.Shutdown();
        }
        // dev_trace("WriteMsg: " + uint(5 + msgData.Length) + " bytes");
    }
}

const uint32 ONE_MEGABYTE = 1024 * 1024;

class RawMessage {
    uint8 msgType;
    string msgData;
    Json::Value@ msgJson;
    uint readStrLen;

    RawMessage() {}

    void ReadFromSocket(Net::Socket@ s, uint len) {
        msgType = s.ReadUint8();
        // possible here: handle some messages differently
        readStrLen = s.ReadUint32();
        if (len != readStrLen + 5) {
            warn("Message length mismatch: " + len + " != " + readStrLen + 5 + " / type: " + msgType);
        }
        try {
            msgData = s.ReadRaw(readStrLen);
        } catch {
            error("Failed to read message data with len: " + readStrLen);
            return;
        }
        try {
            @msgJson = Json::Parse(msgData);
        } catch {
            error("Failed to parse message json: " + msgData);
            return;
        }
        string msgTypeStr = tostring(MessageResponseTypes(msgType));
        if (!msgJson.HasKey(msgTypeStr)) {
            error("Message type not found in json: " + msgTypeStr);
        } else {
            @msgJson = msgJson[msgTypeStr];
        }
    }

    bool get_IsPing() {
        return msgType == uint8(MessageResponseTypes::Ping);
    }
}
