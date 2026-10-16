### **Example** ###

### Example 1 ###
```ahk
Promise(Callback).then(result => Log(result))   // 222
Log(111)                                        // 111

Callback(resolve, reject) {
    Timer.setTimeout(500, () => resolve(222))
}
```

### Example 2 .try .then .catch .finally .resolve .reject .delay ###
```ahk
Promise
    .try(() => Log(111) && Promise.resolve(333))                    // 111
    .delay(500)
    .then(prevResult => Log(prevResult) && Promise.reject("555"))   // 333
    .then(() => Log("never"))
    .finally(() => Log(444))                                        // 444
    .catch(error => Log(error))                                     // 555

Log(222)                                                            // 222
```

### Example 3 .cycle .timeout ###
```ahk
Promise.cycle((i, brk) => Promise
    .try(() => Log(i))                  // 1 2 3 4 5
    .delay(100)
    .then(() => i >= 9 && brk())
)
.timeout(450)
.then(() => Log(6))                     // 6
```

### Example 4 .all (also .any .race) ###
```ahk
Promise
    .all([
        Promise.resolve(111),
        Promise.delay(1000).then(() => 333)
        Promise.delay(500).then(() => 222)
    ]) // after 1000 ms
    .then(results => Log(String(results[1]) . String(results[2]) . String(results[3]))) // 111333222
```

### Example 5 ###
```ahk
class Promise {
    ...

    static OnMessageID := 100001
    static OnMessageTasks := Map()

    static createTask(call) {
        static taskID := 1
        Promise.OnMessageTasks.Set(taskID, call)
        return taskID++
    }
    static deleteTask(taskID) {
        Promise.OnMessageTasks.Delete(taskID)
    }
    static _initOnMessage() {
        OnMessage(Promise.OnMessageID, Promise._onMessageHandler)
    }   
    static _onMessageHandler(taskID, *) {
        if Promise.OnMessageTasks.Has(taskID) {
            callback := Promise.OnMessageTasks.Delete(taskID)
            callback.Call()
        }
    }
}

Promise._initOnMessage()
```

```ahk
BitBltUtils_CaptureAsync(hdcDest, hdcSrc, width, height) {
    task := { id: 0 }
    
    return Promise
        .retry(() => Promise(executeCallback)
            .timeout(50)
            .finally(() => Promise.deleteTask(task.id))
        , 2)

    executeCallback(resolve, reject) {
        task.id := Promise.createTask(() => resolve())
        
        try {
            DllCall(__BitBltUtilsDllPath . "\BitBltCaptureAsync",
                "Ptr", hdcDest,
                "Ptr", hdcSrc,
                "Int", width,
                "Int", height,
                "Int", task.id,
                "UInt", Promise.OnMessageID,
                "Ptr", A_ScriptHwnd,
                "CDecl")
        } catch as error {
            reject(error)
        }
    }
}
```

```cpp
__declspec(dllexport) void BitBltCapture(
    HDC hdcDest,
    HDC hdcSrc,
    int width,
    int height
) {
    BitBlt(hdcDest, 0, 0, width, height, hdcSrc, 0, 0, SRCCOPY);
}
__declspec(dllexport) void BitBltCaptureAsync(
    HDC hdcDest,
    HDC hdcSrc,
    int width,
    int height,
    int callID,
    UINT messageID,
    HWND ahkHwnd
) {
    std::thread([=]() {
        BitBltCapture(hdcDest, hdcSrc, width, height);
        PostMessage(ahkHwnd, messageID, 0, callID);
    }).detach();
}
```
