# mix run lib/week4/main.exs

numberOfPools = 3

:ets.new(:loadBal, [:set, :public, :named_table])
:ets.insert(:loadBal, {:length, numberOfPools})

UserCache.start_link()

Week4.StatMaker.start_link()

# Each pool formed out of LB and PS is supervised one for all
Enum.each(1..numberOfPools, fn n -> Week4.GenericPool.start_link(n) end)

Week4.StreamReader.start_link("http://localhost:4000/tweets/1")
Week4.StreamReader.start_link("http://localhost:4000/tweets/2")

# Week4.Cache.start_link()

receive do
  _ -> IO.inspect("Hi")
end
