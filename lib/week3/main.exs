# mix run lib/week2/main.exs

Week3.StatMaker.start_link()
Week3.PrinterSupervisor.start_link()


Week3.LoadBalancer.start_link()
Week3.StreamReader.start_link("http://localhost:4000/tweets/1")
Week3.StreamReader.start_link("http://localhost:4000/tweets/2")
Week3.Cache.start_link()

receive do
  _ -> IO.inspect("Hi")
end
