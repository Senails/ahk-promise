class TimerTask {
    static idCounter := 1

    __New(c, d, i) {
        this.id := TimerTask.idCounter++

        this.callback := c
        this.date := d
        this.interval := i

        Timer._insertTaskToList(this)
        Timer._updateTimer()
    }

    execute() {
        if this.callback.MaxParams = 1 {
            this.callback.Call(this.id)
        } else {
            this.callback.Call()
        }
    }
}

class Timer {
    static _taskList := []
    static _timerHandlerCallback := Timer._handleTimerEvent.Bind(Timer)

    static setTimeout(callback, ms := 16) {
        task := TimerTask(callback, A_TickCount + ms, 0)
        return task.id
    }
    static setInterval(callback, ms := 16) {
        task := TimerTask(callback, A_TickCount + ms, ms > 0 ? Max(1, ms) : 1)
        return task.id
    }

    static clearInterval(id) {
        Timer._removeTaskFromListById(id)
    }
    static clearTimeout(id) {
        Timer._removeTaskFromListById(id)
    }

    static _insertTaskToList(task) {
        size := Timer._taskList.Length
        
        ; Ищем место для вставки
        insertIndex := size + 1
        for i, existingTask in Timer._taskList {
            if task.date < existingTask.date {
                insertIndex := i
                break
            }
        }
        
        ; Вставляем на найденное место
        Timer._taskList.InsertAt(insertIndex, task)
    }
    static _removeTaskFromListById(id) {
        for index, task in Timer._taskList {
            if task.id == id {
                Timer._taskList.RemoveAt(index)
                Timer._updateTimer()
                return true
            }
        }

        return false
    }

    static _updateTimer() {
        ; Останавливаем старый таймер
        SetTimer(Timer._timerHandlerCallback, 0)
        
        ; Если задач нет - выходим
        if Timer._taskList.Length = 0 {
            return
        }
        
        ; Вычисляем время до следующей задачи
        nextDate := Timer._taskList[1].date
        now := A_TickCount
        timeToNext := Max(1, nextDate - now)
        
        SetTimer(Timer._timerHandlerCallback, -timeToNext)
    }
    static _handleTimerEvent() {
        ; Выполняем задачи, пока есть те, чье время настало
        while Timer._taskList.Length > 0 {
            task := Timer._taskList[1]
            now := A_TickCount
            
            ; Если время еще не настало - выходим
            if task.date > now {
                break
            }
            
            ; Удаляем задачу из списка
            Timer._taskList.RemoveAt(1)
            
            ; Если это интервальная задача - пересчитываем время и вставляем обратно
            if task.interval > 0 {
                task.date := task.date + task.interval
                Timer._insertTaskToList(task)
            }
            
            task.execute()
        }
        
        ; Обновляем таймер для следующей задачи
        Timer._updateTimer()
    }

    static getMilliseconds() {
        freq := 0
        counter := 0
        DllCall("QueryPerformanceFrequency", "Int64*", &freq)
        DllCall("QueryPerformanceCounter", "Int64*", &counter)

        return ((counter * 1000000) // freq) // 1000
    }
}
