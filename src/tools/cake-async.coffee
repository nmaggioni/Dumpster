#
# cake-async
# (c) Ricardo Tomasi 2013
# MIT licensed <ricardo.mit-license.org>
# https://github.com/ricardobeat/cake-async
#

bus = new (require('events').EventEmitter)
queue = []
state = false
aid = 0

run = (waiting = state) ->
    return if (state = waiting) or not next = queue.shift()
    invoke state = next

async_invoke = (name) ->
    task "async:#{name}", ->
        bus.once "#{name}.done", -> run false
        run()
    queue.push name
    return "async:#{name}" # will be returned to invoke() method

async_task = (name, description, action) ->
    task name, description, (options) ->
        action.call @, options, => bus.emit "#{@name}.done"

async = (_task) ->
    return async_invoke _task if typeof _task is 'string'
    return async_task _task.name, _task.description, _task.action

async.end = (cb) ->
    task "async:#{++aid}", ->
        cb()
        run false
    queue.push "async:#{aid}"
    return

module.exports = async
