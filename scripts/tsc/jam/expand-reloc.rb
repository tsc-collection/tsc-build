=begin
  vim: set sw=2:
  Copyright (c) 2009, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

def collect_reloc_for_expand(with, without, top, items)
  items.each do |_item|
    case _item
      when %r{[.]reloc$}
        collect_reloc_for_expand with, without, top, File.readlines(_item).map { |_line|
          top + _line.strip
        }

      when %r{ -$}
        without << _item.slice(0...-2)

      else
        with << _item
    end
  end
end

def expand_reloc(top, items)
  with = []
  without = []

  collect_reloc_for_expand(with, without, top.strip, items)

  with.reject { |_item|
    without.include? _item.sub(%r{[.][^.]*$}, '')
  }
end
