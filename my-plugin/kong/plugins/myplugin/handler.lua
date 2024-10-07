local http = require "resty.http"
local xmlua = require "xmlua"              -- XML parsing library
local KongGzip = require "kong.tools.gzip" -- Gzip library for decompression

local plugin = {
    PRIORITY = 1000,
    VERSION = "0.1",
}

function plugin:header_filter(conf)
    kong.response.clear_header("Content-Length") -- Ensure the new body size is recalculated
end

local function transform_xml(xml_doc)
  local search_terms = { "DigitalAPI", "DigitalWeb", "NDC", "Unmapped" }

  local nodes = xml_doc:search("//*[local-name()='ChannelType']")
  --kong.log.err("Found ", #nodes, " 'ChannelType' nodes")

  for _, term in ipairs(search_terms) do
      -- Search based on local name ignoring the namespace, also log the search term
      local nodes = xml_doc:search("//*[local-name()='ChannelType' and contains(text(), '" .. term .. "')]")

      -- If no nodes are found, log a message
      -- if #nodes == 0 then
      --     kong.log.err("No nodes found for term: ", term)
      -- else
      --     kong.log.err("Found ", #nodes, " node(s) for term: ", term)
      -- end

      -- Log and transform the nodes
      for _, node in ipairs(nodes) do
          -- Log the content of the node before the transformation
          -- kong.log.err("Node content before transformation: ", node:text())

          -- Replace the content
          local success, err = pcall(function()
              node:set_content("API") -- Change text to "API"
          end)
          if not success then
              kong.log.err("Error setting text on node: ", err)
          else
              kong.log.err("Successfully replaced '" .. term .. "' with 'API'")
          end

          -- Log the content of the node after the transformation
          -- kong.log.err("Node content after transformation: ", node:text())
      end
  end

  return xml_doc
end
function plugin:body_filter()
  local res_body = kong.response.get_raw_body()

  if res_body then
      local is_gzipped = kong.response.get_header("Content-Encoding") == "gzip"
      if is_gzipped then
          kong.log.debug("Decompressing Gzipped response body")
          local decompressed_body, err = KongGzip.inflate_gzip(res_body)
          if not decompressed_body then
              kong.log.err("Failed to decompress Gzip body: ", err)
              return
          end
          res_body = decompressed_body
      end

      local xml_doc, err = xmlua.XML.parse(res_body)
      if not xml_doc then
          kong.log.err("Failed to parse XML: ", err)
          return
      end

      local transformed_xml_doc = transform_xml(xml_doc)
      local transformed_xml = transformed_xml_doc:to_xml()


     -- kong.response.set_raw_body(transformed_xml)


      -- If the original response was Gzipped, compress it again
    if is_gzipped then
      kong.log.err("Recompressing the transformed XML as Gzip")
      local gzipped_body, err = KongGzip.deflate_gzip(transformed_xml)
      if not gzipped_body then
          kong.log.err("Failed to recompress the transformed body: ", err)
          return
      end
      ngx.arg[1] = gzipped_body
      --kong.response.set_raw_body(transformed_xml)
      kong.log.err("Setting transformed gzipped body, size: ", #ngx.arg[1])
  else
      -- If not Gzipped, set the transformed XML body
      ngx.arg[1] = transformed_xml
      kong.log.err("Setting transformed body, size: ", #ngx.arg[1])
  end

  --kong.response.set_raw_body(gzipped_body)
  -- Ensure the last chunk flag is set
  if not ngx.arg[2] then
      return
  end

  --ngx.arg[2] = true
  kong.log.err("Transformed response body successfully: ", ngx.arg[1])

  end
end




return plugin
