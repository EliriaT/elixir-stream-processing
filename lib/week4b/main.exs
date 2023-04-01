# mix run lib/week4/main.exs

Week4.LBRegister.start_link()

Week4.LBRegister.addNewLoadBalancerType(:engage)
Week4.LBRegister.addNewLoadBalancerType(:sentiment)
Week4.LBRegister.addNewLoadBalancerType(:redacter)
Week4.LBRegister.addNewLoadBalancerType(:printer)

UserCacheB.start_link()

Week4B.StatMaker.start_link()

# Each pool formed out of LB and PS is supervised one for all
Week4B.GenericPool.start_link(:printer)
Week4B.GenericPool.start_link(:engage)
Week4B.GenericPool.start_link(:sentiment)
Week4B.GenericPool.start_link(:redacter)

Week4B.StreamReader.start_link("http://localhost:4000/tweets/1")
Week4B.StreamReader.start_link("http://localhost:4000/tweets/2")



receive do
  _ -> IO.inspect("Hi")
end
