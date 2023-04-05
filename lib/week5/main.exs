# mix run lib/week4/main.exs

Week5.LBRegister.start_link()

Week5.LBRegister.addNewLoadBalancerType(:engage)
Week5.LBRegister.addNewLoadBalancerType(:sentiment)
Week5.LBRegister.addNewLoadBalancerType(:redacter)
Week5.LBRegister.addNewLoadBalancerType(:printer)

UserCache5.start_link()

Week5.StatMaker.start_link()

Week5.Batcher.start_link()

Week5.Aggregator.start_link()


# Each pool formed out of LB and PS is supervised one for all
Week5.GenericPool.start_link(:printer)
Week5.GenericPool.start_link(:engage)
Week5.GenericPool.start_link(:sentiment)
Week5.GenericPool.start_link(:redacter)

Week5.StreamReader.start_link("http://localhost:4000/tweets/1")
Week5.StreamReader.start_link("http://localhost:4000/tweets/2")

:timer.sleep(2000)
Week5.Batcher.ask_for_messages()
Week5.Batcher.schedule_work()

receive do
  _ -> IO.inspect("Hi")
end
