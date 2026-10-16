#include "../index.ahk"  ; Подключаем наш класс таймера

; Аналог OnInit в AHK — выполняется при запуске скрипта
OnInit() {
    Log("Promise test start")

    test1() {
        ; Log("Promise test1 start new Promise(), Promise.then, Promise.catch, Promise.finally, Promise.delay")
        stepIndex := 0
        isSuccess := true

        tickCount1 := 0
        tickCount2 := 0

        return Promise(mainCallback)
            .then(then1Callback)
            .then(then2Callback)
            .delay(1000)
            .then(then3Callback)
            .then(() => Promise.reject("test error"))
            .then(then4Callback)
            .finally(finallyCallback)
            .catch(catchCallback)
            .then(() => isSuccess && Log("Promise test1 complete new Promise(), Promise.then, Promise.catch, Promise.finally, Promise.delay"))

        mainCallback(res, rej) {
            if (stepIndex == 0) {
                stepIndex++
            } else {
                Log("Log 1 stepIndex == 0 failed")
                isSuccess := false
            }

            Timer.SetTimeout(SetTimeoutExecute, 1500)

            if (stepIndex == 1) {
                stepIndex++
            } else {
                Log("Log 2 stepIndex == 1 failed")
                isSuccess := false
            }

            SetTimeoutExecute() {
                if (stepIndex == 2) {
                    stepIndex++

                    ; Log("Log 3 stepIndex == 2")
                } else {
                    isSuccess := false
                }

                res("trueResult")
            }
        }
        then1Callback(result) {
            if (stepIndex == 3 && result == "trueResult") {
                stepIndex++

                ; Log("Log 4 stepIndex == 3 result == trueResult")
            } else {
                isSuccess := false
            }

            return result
        }
        then2Callback(result) {
            if (stepIndex == 4) {
                stepIndex++
                tickCount1 := A_TickCount

                ; Log("Log 5 stepIndex == 4 tickCount1 == " . String(tickCount1))
            } else {
                isSuccess := false
            }

            return result
        }
        then3Callback(result) {
            tickCount2 := A_TickCount

            if (
                stepIndex == 5
                && tickCount2 - tickCount1 >= 1000
                && result == "trueResult"
            ) {
                stepIndex++

                ; Log("Log 6 stepIndex == 5")
                ; Log("tickCount1 == " . String(tickCount1) . " tickCount2 == " . String(tickCount2) . " tickCount2 - tickCount1 >= 1000")
                ; Log("result == trueResult")
            } else {
                isSuccess := false
            }

            return result
        }
        then4Callback(result) {
            isSuccess := false
        }
        finallyCallback() {
            if (stepIndex == 6) {
                stepIndex++

                ; Log("Log 7 finallyCallback stepIndex == 6")
            }

            return Promise.reject("skip finally error")
        }
        catchCallback(error) {
            if (stepIndex == 7 && String(error) == "test error") {
                stepIndex++

                ; Log("Log 8 stepIndex == 7 String(error) == test error")
            } else {
                isSuccess := false
            }
        }
    }

    test2() {
        ; Log("Promise test2 start Promise.all Promise.any Promise.rase")

        PromiseAllSuccess := false
        PromiseRaseSuccess := false
        PromiseAnySuccess := false

        return Promise
            .try(PromiseAllTest)
            .then(PromiseRaseTest)
            .then(PromiseAnyTest)
            .then(() => PromiseAllSuccess && PromiseRaseSuccess && PromiseAnySuccess && Log("Promise test2 complete Promise.all Promise.any Promise.rase"))

        PromiseAllTest() {
            isSuccess := true

            promise1Complete := false
            promise2Complete := false
            promise3Complete := false

            tickCount11 := 0
            tickCount12 := 0

            tickCount21 := 0
            tickCount22 := 0

            return Promise
                .try(() => tickCount11 := A_TickCount)
                .then(() => Promise
                    .all([
                        Promise.delay(1000).then(() => promise1Complete := true),
                        Promise.delay(500).then(() => promise2Complete := true),
                        Promise.delay(1500).then(() => promise3Complete := true),
                    ])
                )
                .then(ThenCallback)
                .then(() => tickCount21 := A_TickCount)
                .then(() => Promise
                    .all([
                        Promise.delay(1000).then(() => Promise.reject("promise1 reject")),
                        Promise.delay(500),
                        Promise.delay(1500),
                    ])
                )
                .catch(CatchCallback)
                .then(() => isSuccess && PromiseAllSuccess := true)
                ; .then(() => isSuccess && Log("Promise.all test complete"))

            ThenCallback() {
                tickCount12 := A_TickCount

                if (
                    promise1Complete
                    && promise2Complete
                    && promise3Complete
                    && tickCount12 - tickCount11 >= 1500
                ) {
                    ; Log("Log 1 promise1Complete, promise2Complete, promise3Complete == true tickCount12 - tickCount11 > 1500")
                } else {
                    isSuccess := false
                }
            }
            CatchCallback(error) {
                tickCount22 := A_TickCount

                if (
                    error == "promise1 reject"
                    && tickCount22 - tickCount21 >= 1000
                    && tickCount22 - tickCount21 < 1500
                ) {
                    ; Log("Log 2 error == "promise1 reject"  tickCount22 - tickCount21 >= 1000  tickCount22 - tickCount21 < 1500")
                } else {
                    isSuccess := false
                }
            }

        }
        PromiseRaseTest() {
            isSuccess := true

            return Promise
                .try(() => Promise
                    .race([
                        Promise.delay(500).then(() => Promise.reject("Promise 1 reject")),
                        Promise.delay(2500).then(() => Promise.resolve("Promise 2 resolve")),
                        Promise.delay(1500).then(() => Promise.resolve("Promise 3 resolve")),
                    ])
                )
                .catch(CatchCallback)
                .then(() => Promise
                    .race([
                        Promise.delay(3500).then(() => Promise.resolve("Promise 1 resolve")),
                        Promise.delay(2500).then(() => Promise.resolve("Promise 2 resolve")),
                        Promise.delay(1500).then(() => Promise.resolve("Promise 3 resolve")),
                    ])
                )
                .then(ThenCallback)
                .then(() => isSuccess && PromiseRaseSuccess := true)
                ; .then(() => isSuccess && Log("Promise.race test complete"))

            CatchCallback(error) {
                if (error == "Promise 1 reject") {
                    ; Log("Log 1 error == Promise 1 reject")
                } else {
                    isSuccess := false
                }
            }
            ThenCallback(result) {
                if (result == "Promise 3 resolve") {
                    ; Log("Log 2 result == Promise 3 resolve")
                } else {
                    isSuccess := false
                }
            }
        }
        PromiseAnyTest() {
            isSuccess := true

            return Promise
                .try(() => Promise
                    .any([
                        Promise.delay(500).then(() => Promise.reject("Promise 1 reject")),
                        Promise.delay(2500).then(() => Promise.reject("Promise 2 reject")),
                        Promise.delay(1500).then(() => Promise.reject("Promise 3 reject")),
                    ])
                )
                .catch(CatchCallback)
                .then(() => Promise
                    .any([
                        Promise.delay(3500).then(() => Promise.resolve("Promise 1 resolve")),
                        Promise.delay(2500).then(() => Promise.resolve("Promise 2 resolve")),
                        Promise.delay(1500).then(() => Promise.reject("Promise 3 reject")),
                    ])
                )
                .then(ThenCallback)
                .then(() => isSuccess && PromiseAnySuccess := true)
                ; .then(() => isSuccess && Log("Promise.any test complete"))

            CatchCallback(error) {
                if (error == "unknown error") {
                    ; Log("Log 1 error == unknown error")
                } else {
                    isSuccess := false
                }
            }
            ThenCallback(result) {
                if (result == "Promise 2 resolve") {
                    ; Log("Log 2 result == Promise 3 resolve")
                } else {
                    isSuccess := false
                }
            }
        }
    }

    test3() {
        ; Log("Promise test3 start Promise.cycle Promise.cycleForIn")
        isSuccess := true

        tickCount1 := 0
        tickCount2 := 0
        cycleCount := 0

        testArrayInput := [1, 2, 3, 4, 5]
        testArrayOutput := []

        return Promise
            .try(() => tickCount1 := A_TickCount)
            .then(() => Promise.cycle((index, brk) => index < 11 ? cycleCount++ && Promise.delay(100) : brk()))
            .then(() => tickCount2 := A_TickCount)
            .then(thenCallback1)
            .then(() => Promise.cycleForIn(testArrayInput, (elem, index) => testArrayOutput.Push(elem)))
            .then(thenCallback2)
            .then(() => isSuccess && Log("Promise test3 start Promise.cycle Promise.cycleForIn"))

        thenCallback1() {
            difference := tickCount2 - tickCount1

            if (difference >= 1000 && difference < 1200 && cycleCount == 10) {
                ; Log("Log 1 test Promise.cycle complete")
            } else {
                isSuccess := false
            }
        }
        thenCallback2() {
            if (testArrayInput.Length == testArrayOutput.Length && testArrayInput[1] == testArrayOutput[1]) {
                ; Log("Log 2 test Promise.cycleForIn complete")
            } else {
                isSuccess := false
            }
        }
    }

    test4() {

    }

    test5() {

    }

    Promise
        .try(test1)
        .then(test2)
        .then(test3)

    ; retryIndex := 0

    ; Promise
    ;     .retry(mainCall, 3, onErrorCall)
    ;     .then(cycleThenCallback)
    ;     .catch(cycleCatchCallback)


    ; mainCall() {
    ;     return Promise
    ;         .try(() => Promise.delay(50 - retryIndex * 10))
    ;         .timeout(21)
    ; }
    ; onErrorCall(error, index) {
    ;     Log("onErrorCall " . String(error) . " " . String(index))
    ;     retryIndex++

    ;     ; return Promise.reject(111)
    ; }

    ; Promise(Callback1)
    ;     .then(text => Log(text) && text)
    ;     .delay(1000)
    ;     .then(text => Log(text))
    ;     .catch(error => Log(error))
    

    ; Callback1(res, rej) {
    ;     Log("000")
    ;     Timer.SetTimeout(() => res("12345"), 1500)
    ;     Log("111")
    ; }

    ; Promise
    ; .any([
    ;     Promise((res, rej) => rej("test1")).delay(2000),
    ;     Promise.try(() => "test2").delay(1000),
    ; ])
    ; .then(result => thenCallback(result))
    ; .catch(error => errorCallback(error))
    
    ; thenCallback(result) {
    ;     Log(result)
    ; }
    ; errorCallback(error) {
    ;     Log(error.Message)
    ; }
    
    i := 0

    ; promise1 := Promise
    ;     .cycle(cycleCallback)
    ;     .then(cycleThenCallback)
    ;     .catch(cycleCatchCallback)

    cycleCallback(index, brk) {
        if index >= 1500 {
            brk()
        }

        ; if i > 500 {
        ;     Log("index = " index)
        ;     i := 0
        ; }

        ; i++
        Log("index = " index)
        ; return Promise
        ;     .try(() => 1)
        ;     .then(throwError)
        ;     .then(res => res)
        ;     .catch(() => 3)
        ;     .finally(() => 1 + 1)
        ;     .then(num => num)
        return Promise.delay()
    }
    cycleThenCallback(result) {
        Log("cycleThenCallback" . String(result))
        return false 
    }
    cycleCatchCallback(error) {
        Log("cycleCatchCallback " . String(error))
        return error
    }
    throwError() {
        throw Error("Error")
    }



    ; Вспомогательная функция для вывода
    Log(msg) {
        timestamp := FormatTime(, "HH:mm:ss")
        OutputDebug timestamp ": " msg "`n"

        return true
    }
}


; Запускаем при старте
OnInit()
