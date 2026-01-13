local InputQueue = {}

function InputQueue.new()
   return {
      actions = {}
   }
end

function InputQueue.push(queue, action)
   queue.actions[#queue.actions + 1] = action
end

function InputQueue.drain(queue, handler)
   for actionIndex = 1, #queue.actions do
      handler(queue.actions[actionIndex])
      queue.actions[actionIndex] = nil
   end
end

return InputQueue
