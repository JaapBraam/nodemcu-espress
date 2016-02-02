------------------------------------------------------------------------------
-- send file
------------------------------------------------------------------------------
return function(res, filename, status)
 local buffersize = 512
 local offset = 0
 local buf
 local more

 if not file.open(filename, "r") then
  local f = loadfile("http_not_found.lc")
  f()(res)
  f = nil
 else
  buf = "HTTP/1.1 " .. tostring(status or res.statuscode) .. " " .. dofile('http-' .. tostring(status or res.statuscode)) .. "\r\n"
  --   Write response headers
  res:addheader("Server", "NodeMCU")
  res:addheader("Transfer-Encoding", "chunked")
  for key, value in pairs(res.headers) do
   -- send header
   buf = buf .. key .. ": " .. value .. "\r\n"
  end
  buf = buf .. "\r\n"
  res.conn:send(buf)
  more = true

  -- Send file body
  local function sendnextchunk()
   collectgarbage("collect")
   file.seek("set", offset)
   buf = file.read(buffersize)
   res.conn:send(("%X\r\n"):format(#buf) .. buf .. "\r\n")
   more = (#buf == buffersize)
   if more then
    offset = offset + buffersize
   end
  end

  res.conn:on("sent", function(conn)
   if (more) then
    sendnextchunk()
   else
    -- Manually free resources for gc
    buf = nil
    buffersize = nil
    offset = nil
    sendnextchunk = nil
    -- Close connection
    conn:send("0\r\n\r\n")
    file.close()
    conn:close()
   end
  end)
 end
end