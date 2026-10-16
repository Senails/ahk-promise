#include "./Timer.ahk"

class Promise {
    static PromiseType_Main := 1
    static PromiseType_Then := 2
    static PromiseType_Catch := 3

    static PromiseStatusType_Resolved := 1
    static PromiseStatusType_Rejected := 2
    static PromiseStatusType_inProgress := 3

    __New(call := 0, param := 0, _parentPromise := 0, _promiseType := Promise.PromiseType_Main, _status := Promise.PromiseStatusType_inProgress, _result := 0, _errorResult := 0) {
        this._status := _status
        this._result := _result
        this._errorResult := _errorResult

        if this._status == Promise.PromiseStatusType_inProgress {
            this._promiseType := _promiseType
            this._childrenPromises := []

            if (this._promiseType == Promise.PromiseType_Main) {
                this._invokeCallbackMain(call, param)
            } else {
                this._callback := call ? call : () => true
                this._param := param
                this._parentPromise := _parentPromise
            }
        }
    }

    then(call, param := 0) {
        if (this._status == Promise.PromiseStatusType_Resolved) {
            return this._invokeCallbackThen(call, param)
        }
        if (this._status == Promise.PromiseStatusType_Rejected) {
            return this
        }

        childPromise := Promise(call, param, this, Promise.PromiseType_Then)
        this._childrenPromises.Push(childPromise)
        return childPromise
    }
    catch(call, param := 0) {
        if (this._status == Promise.PromiseStatusType_Rejected) {
            return this._invokeCallbackCatch(call, param)
        }
        if (this._status == Promise.PromiseStatusType_Resolved) {
            return this
        } 

        childPromise := Promise(call, param, this, Promise.PromiseType_Catch)
        this._childrenPromises.Push(childPromise)
        return childPromise
    }
    finally(call, param := 0) {
        return this._status == Promise.PromiseStatusType_inProgress
            ? this.then(() => this._invokeCallbackFinally(call, param)).catch(() => this._invokeCallbackFinally(call, param))
            : this._invokeCallbackFinally(call, param)
    }

    _resolve(param := 0) {
        if this._status == Promise.PromiseStatusType_inProgress {
            this._status := Promise.PromiseStatusType_Resolved
            this._result := param 

            for childrenPromise in this._childrenPromises {
                if (childrenPromise._promiseType == Promise.PromiseType_Then) {
                    childrenPromise._executeCallbackThen()
                } else if (childrenPromise._promiseType == Promise.PromiseType_Catch) {
                    childrenPromise._resolve(this._result)
                }
            }

            this._callback := 0
            this._param := 0
            this._parentPromise := 0
            this._childrenPromises := 0
        }
    }
    _reject(param := 0) {
        if this._status == Promise.PromiseStatusType_inProgress {
            this._status := Promise.PromiseStatusType_Rejected
            this._errorResult := param 

            for childrenPromise in this._childrenPromises {
                if (childrenPromise._promiseType == Promise.PromiseType_Then) {
                    childrenPromise._reject(this._errorResult)
                } else if (childrenPromise._promiseType == Promise.PromiseType_Catch) {
                    childrenPromise._executeCallbackCatch()
                }
            }

            this._callback := 0
            this._param := 0
            this._parentPromise := 0
            this._childrenPromises := 0
        }
    }

    _executeCallbackThen() {
        try {
            mayBePromise := this._callback.MaxParams >= 2
                ? this._callback.Call(this._parentPromise._result, this._param)
                : this._callback.MaxParams >= 1
                    ? this._callback.Call(this._parentPromise._result)
                    : this._callback.Call()

            return mayBePromise is Promise
                ? mayBePromise.then((result := 0) => this._resolve(result)).catch((error := "unknown error") => this._reject(error))
                : this._resolve(mayBePromise)

        } catch as error {
            this._reject(error)
        }
    }
    _executeCallbackCatch() {
        try {
            mayBePromise := this._callback.MaxParams >= 2
                ? this._callback.Call(this._parentPromise._errorResult, this._param)
                : this._callback.MaxParams >= 1
                    ? this._callback.Call(this._parentPromise._errorResult)
                    : this._callback.Call()

            return mayBePromise is Promise
                ? mayBePromise.then((result := 0) => this._resolve(result)).catch((error := "unknown error") => this._reject(error))
                : this._resolve(mayBePromise)

        } catch as error {
            this._reject(error)
        }
    }

    _invokeCallbackMain(call := () => true, param := 0) {
        try {
            if call.MaxParams >= 3 {
                call.Call((result := 0) => this._resolve(result), (error := "unknown error") => this._reject(error), param)
            } else if call.MaxParams >= 2 {
                call.Call((result := 0) => this._resolve(result), (error := "unknown error") => this._reject(error))
            } else {
                call.Call((result := 0) => this._resolve(result))
            }
        } catch as error {
            this._status := Promise.PromiseStatusType_Rejected
            this._errorResult := error
        }
    }
    _invokeCallbackThen(call, param := 0) {
        try {
            mayBePromise := call.MaxParams >= 2
                ? call.Call(this._result, param)
                : call.MaxParams >= 1
                    ? call.Call(this._result)
                    : call.Call()

            return mayBePromise is Promise ? mayBePromise : Promise.resolve(mayBePromise)
        } catch as error {
            return Promise.reject(error)
        }
    }
    _invokeCallbackCatch(call, param := 0) {
        try {
            mayBePromise := call.MaxParams >= 2
                ? call.Call(this._errorResult, param)
                : call.MaxParams >= 1
                    ? call.Call(this._errorResult)
                    : call.Call()

            return mayBePromise is Promise ? mayBePromise : Promise.resolve(mayBePromise)
        } catch as error {
            return Promise.reject(error)
        }
    }
    _invokeCallbackFinally(call, param := 0) {
        try {
            mayBePromise := call.MaxParams >= 2
                ? call.Call(this._result, param)
                : call.MaxParams >= 1
                    ? call.Call(this._result)
                    : call.Call()

            return mayBePromise is Promise ? mayBePromise.then(() => this).catch(() => this) : this
        } catch as error {
            return this
        }
    }

    thenIf(condition, call := 0, param := 0) {
        return condition ? this.then(call, param) : this
    }
    delay(ms := 1) {
        return this.then(result => Promise.delay(ms, result))
    }
    cycle(call) {
        return this.then(() => Promise.cycle(call))
    }
    cycleForIn(arr, call) {
        return this.then(() => Promise.cycleForIn(arr, call))
    }
    timeout(ms := 16) {
        return Promise.race([this, Promise.delay(ms).then(() => Promise.reject("timeout error"))])
    }

    static try(call) {
        try {
            mayBePromise := call.Call()
            return mayBePromise is Promise ? mayBePromise : Promise.resolve(mayBePromise)
        } catch as error {
            return Promise.reject(error)
        }
    }
    static resolve(value := 0) {
        return Promise(,,,, Promise.PromiseStatusType_Resolved, value)
    }
    static reject(error := "unknown error") {
        return Promise(,,,, Promise.PromiseStatusType_Rejected,, error)
    }
    static delay(ms := 1, result := 0) {
        return Promise(promiseCallback)

        promiseCallback(res, rej) {
            Timer.setTimeout(timerCallback, ms)

            timerCallback() {
                res(result)
            }
        }
    }
    static cycle(call) {
        iterationIndex := 1
        running := true
        return Promise.try(() => executeCallback())

        bkrCallback() {
            running := false
        }
        oneIterationCallback() {
            return running && call(iterationIndex++, bkrCallback)
        }
        executeCallback(recurseDeep := 1) {
            innerExecuteCallback() {
                return running && recurseDeep <= 30 && executeCallback(recurseDeep + 1)
            }

            return Promise
                .try(oneIterationCallback)
                .thenIf(running, oneIterationCallback)
                .thenIf(running, oneIterationCallback)
                .thenIf(running, oneIterationCallback)
                .thenIf(running, oneIterationCallback)
                .thenIf(running, oneIterationCallback)
                .thenIf(running, oneIterationCallback)
                .thenIf(running, oneIterationCallback)
                .thenIf(running, oneIterationCallback)
                .thenIf(running, oneIterationCallback)
                .thenIf(running, innerExecuteCallback)
                .thenIf(running, innerExecuteCallback)
        }
    }
    static cycleForIn(arr, call) {
        return Promise.cycle(executeIteration)

        executeIteration(index, brk) {
            if (index > arr.Length) {
                brk()
            } else {
                return call.MaxParams >= 2
                    ? call.Call(arr[index], index)
                    : call.MaxParams >= 1
                        ? call.Call(arr[index])
                        : call.Call()
            }
        }
    }
    static all(promises) {
        return promises.Length == 0
            ? Promise.resolve(0)
            : Promise(promiseCallback)

        promiseCallback(resolve, reject) {
            allPromises := promises
            resolvedCount := 0
            allResults := []
            Loop allPromises.Length {
                allResults.Push(0)
            }

            for index, promise in allPromises {
                promise.then((res, i) => childCallback(i, res), index).catch(error => reject(error))
            }

            childCallback(index, result) {
                allResults[index] := result
                resolvedCount++

                if resolvedCount == allPromises.Length {
                    resolve(allResults)
                }
            }
        }
    }
    static race(promises) {
        return promises.Length == 0
            ? Promise.resolve(0)
            : Promise(promiseCallback)

        promiseCallback(resolve, reject) {
            allPromises := promises
            for _, promise in allPromises {
                promise.then(thenCallback).catch(catchCallback)
            }

            thenCallback(result) {
                resolve(result)
            }
            catchCallback(error) {
                reject(error)
            }
        }
    }
    static any(promises) {
        return promises.Length == 0
            ? Promise.resolve(0)
            : Promise(promiseCallback)

        promiseCallback(resolve, reject) {
            allPromises := promises
            rejectedCount := 0
            for _, promise in allPromises {
                promise.then(result => resolve(result)).catch(error => childCatchCallback(error))
            }

            childCatchCallback(error) {
                rejectedCount++

                if rejectedCount == allPromises.Length {
                    reject()
                }
            }
        }
    }
    static retry(taskCall, retryCount := 1, onErrorCall := (error, errorIterationIndex) => 0) {
        validatedRetryCount := Max(retryCount, 1)

        taskResult := 0
        errorIterationIndex := 0

        return Promise.cycle(cycleCallback).then(() => taskResult)

        cycleCallback(index, brk) {
            return Promise
                .try(taskCall)
                .then(thenCallback)
                .catch(catchCallback)

            thenCallback(result) {
                taskResult := result
                brk()
            }
            catchCallback(error) {
                if (errorIterationIndex < validatedRetryCount) {
                    retryCatchPromise := Promise.try(onErrorExecute)
                    errorIterationIndex++

                    return retryCatchPromise
                } else {
                    return Promise.reject(error)
                }

                onErrorExecute() {
                    return onErrorCall.MaxParams >= 2
                        ? onErrorCall.Call(error, errorIterationIndex)
                        : onErrorCall.MaxParams >= 1
                            ? onErrorCall.Call(error)
                            : onErrorCall.Call()
                }
            }
        }
    }


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
