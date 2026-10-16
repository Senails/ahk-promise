#include "../Timer.ahk"  ; Подключаем наш класс таймера

global intervalId := 0  ; id для отмены

; Аналог OnInit в AHK — выполняется при запуске скрипта
OnInit() {
    Log("start")

    ; Таймауты с разными параметрами
    Timer.SetTimeout(() => Log("Callback1 Called with value: 10000"), 10000)      ; через 3000мс
    Timer.SetTimeout(() => Log("Callback2 Called with value: void 2000"), 2000)              ; через 2000мс
    
    ; ; Интервал
    global intervalId := Timer.SetInterval(myCallback3, 800)  ; каждые 800мс
    myCallback3() {
        Log("myCallback3 800")
        Timer.ClearInterval(intervalId)
    }
    
    ; ; Типизированные таймеры (в AHK тип не важен — параметр любой)
    Timer.SetTimeout(() => Log("Called with value: " 1000), 1000)         ; через 1000мс с числом
    Timer.SetTimeout(Callback5, 1800)  ; через 1800мс со строкой
    Callback5(idForCancel) {
        Log("myCallback4 1800")
        Timer.ClearInterval(idForCancel)
    }
}

; Вспомогательная функция для вывода
Log(msg) {
    timestamp := FormatTime(, "HH:mm:ss")
    OutputDebug timestamp ": " msg "`n"
}

; Запускаем при старте
OnInit()
