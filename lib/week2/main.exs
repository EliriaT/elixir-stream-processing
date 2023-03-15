# mix run lib/week2/main.exs

Week2.StatMaker.start_link()
Week2.PrinterSupervisor.start_link()
Week2.LoadBalancer.start_link()
Week2.StreamReader.start_link("http://localhost:4000/tweets/1")
Week2.StreamReader.start_link("http://localhost:4000/tweets/2")

receive do
  _ -> IO.inspect("Hi")
end
