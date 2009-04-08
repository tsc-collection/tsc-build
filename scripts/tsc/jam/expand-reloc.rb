=begin
  vim: set sw=2:
  Copyright (c) 2009, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

def expand_reloc(top, items)
  items.map { |_item|
    case _item
      when %r{[.]reloc$}
        expand_reloc top, File.readlines(_item).map { |_line|
          top.strip + _line.strip
        }
      else
        _item
    end
  }.flatten
end
