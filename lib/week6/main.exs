# mix run lib/week4/main.exs

Week6.LBRegister.start_link()

Week6.LBRegister.addNewLoadBalancerType(:engage)
Week6.LBRegister.addNewLoadBalancerType(:sentiment)
Week6.LBRegister.addNewLoadBalancerType(:redacter)
Week6.LBRegister.addNewLoadBalancerType(:printer)

UserCache6.start_link()

Week6.StatMaker.start_link()

Week6.Batcher.start_link()

Week6.Aggregator.start_link()

Week6.TweetDb.start_link()

# Each pool formed out of LB and PS is supervised one for all
Week6.GenericPool.start_link(:printer)
Week6.GenericPool.start_link(:engage)
Week6.GenericPool.start_link(:sentiment)
Week6.GenericPool.start_link(:redacter)

Week6.StreamReader.start_link("http://localhost:4000/tweets/1")
Week6.StreamReader.start_link("http://localhost:4000/tweets/2")

:timer.sleep(2000)
Week6.Batcher.ask_for_messages()
Week6.Batcher.schedule_work()

receive do
  _ -> IO.inspect("Hi")
end
