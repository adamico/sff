local builder = Evolved.builder

builder()
   :name("SYSTEMS.Processing")
   :group(STAGES.OnUpdate)
   :include(TAGS.Processing)
   :execute(function(chunk, entityIds, entityCount)
      for i = 1, entityCount do

      end
   end):build()
