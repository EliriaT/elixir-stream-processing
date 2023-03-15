

Week1.Printer.start_link()
Week1.StatMaker.start_link()
Week1.StreamReader.start_link("http://localhost:4000/tweets/1")
Week1.StreamReader.start_link("http://localhost:4000/tweets/2")

receive do
  _ -> IO.inspect("Hi")
end
