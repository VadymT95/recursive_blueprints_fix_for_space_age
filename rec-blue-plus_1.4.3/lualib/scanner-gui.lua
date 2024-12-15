local AreaScannerGUI = {}

-- Build the scanner gui
function AreaScannerGUI.create_scanner_gui(player, entity)
  local scanner = storage.scanners[entity.unit_number]
  if not scanner then
    player.force.print('AreaScannerGUI.create_scanner_gui scanner data not found. Generating default settings.')
    AreaScanner.on_built(entity, {})
    scanner = storage.scanners[entity.unit_number]
  end

  -- Destroy any old versions
  if player.gui.screen["recursive-blueprints-scanner"] then
    player.gui.screen["recursive-blueprints-scanner"].destroy()
  end

  -- Heading
  local gui = player.gui.screen.add{
    type = "frame",
    name = "recursive-blueprints-scanner",
    style = "invisible_frame",
    direction = "horizontal",
    tags = {["recursive-blueprints-id"] = entity.unit_number}
  }
  gui.auto_center = true
  local main_frame = gui.add{type = "frame", direction = "vertical"}

  GUI_util.add_titlebar(main_frame, gui, entity.localised_name, "recursive-blueprints-close", {"gui.close-instruction"})
  local inner_frame = main_frame.add{type = "frame", direction = "vertical", style = "entity_frame"}
  GUI_util.add_status_indicator(inner_frame, entity)

  -- Scan area (settings and minimap)
  local main_flow = inner_frame.add{type = "flow"}

  -- Settings caption and buttons with labels
  local left_flow = main_flow.add{type = "flow", direction = "vertical"}
  left_flow.style.right_margin = 8
  left_flow.add{
    type = "label",
    style = "heading_2_label",
    caption = {"description.scan-area"},
  }
  local input_flow = left_flow.add{type = "flow", direction = "vertical"}
  input_flow.style.horizontal_align = "right"
  AreaScannerGUI.add_input_setting_line(input_flow, "description.x-offset", "x")
  AreaScannerGUI.add_input_setting_line(input_flow, "description.y-offset", "y")
  AreaScannerGUI.add_input_setting_line(input_flow, "gui-map-generator.map-width", "width")
  AreaScannerGUI.add_input_setting_line(input_flow, "gui-map-generator.map-height", "height")
  AreaScannerGUI.add_input_setting_line(input_flow, "description.filter", "filter", {"recursive-blueprints.filter-lable-tooltip"})

  -- Minimap
  local minimap_frame = main_flow.add{type = "frame", style = "entity_button_frame"}
  minimap_frame.style.size = 256
  minimap_frame.style.vertical_align = "center"
  minimap_frame.style.horizontal_align = "center"
  local minimap = minimap_frame.add{
    type = "minimap",
    surface_index = entity.surface.index,
    force = entity.force.name,
    position = entity.position,
  }
  minimap.style.minimal_width = 16
  minimap.style.minimal_height = 16
  minimap.style.maximal_width = 256
  minimap.style.maximal_height = 256

  inner_frame.add{type = "line"}

  -- Output signals
  local o_line =  inner_frame.add{type = "flow"}
  o_line.add{
    type = "label",
    style = "heading_2_label",
    caption = {"description.output-signals"},
  }
  local toggle_settings = o_line.add{
    type = "sprite-button",
    name = "recursive-blueprints-counter-settings",
    style = "frame_action_button",
    sprite = "utility/side_menu_menu_icon",
    hovered_sprite = "utility/change_recipe",
    clicked_sprite = "utility/change_recipe",
    tooltip = {"recursive-blueprints.counter-settings"},
  }
  toggle_settings.style.left_margin = 5

  local scroll_pane = inner_frame.add{
    type = "scroll-pane",
    style = "deep_slots_scroll_pane",
    direction = "vertical",
    horizontal_scroll_policy = "never",
    vertical_scroll_policy = "auto",
  }
  scroll_pane.style.maximal_height = 164

  --create panel with output signals.
  --this panel will be populatet in AreaScannerGUI.update_scanner_output()
  local output_flow = scroll_pane.add{
    type = "flow",
    style = "packed_vertical_flow",
    direction = "vertical",
  }
  output_flow.style.width = 400
  output_flow.style.minimal_height = 40

  -- Output settings
  local counters_frame = gui.add{type = "frame", direction = "vertical"}
  GUI_util.add_titlebar(counters_frame, gui, {"recursive-blueprints.counter-settings"})
  local inner_frame2 = counters_frame.add{type = "frame", direction = "vertical", style = "entity_frame"}
  inner_frame2.style.minimal_width = 0
  --inner_frame2.style.maximal_height = 600

  local output_settings_header = inner_frame2.add{type="flow"}
  output_settings_header.add{
    type = "label",
    style = "heading_2_label",
    caption = {"", {"description.output-signals"}, " [img=info]"},
    tooltip = {"recursive-blueprints.counter-settings-tooltip"}
  }
  local filler = output_settings_header.add{type = "empty-widget"}
  filler.style.horizontally_stretchable = true
  output_settings_header.add{
    type = "sprite-button",
    name = "recursive-blueprints-reset-counters",
    style = "tool_button_red",
    sprite = "utility/reset",
    hovered_sprite = "utility/reset",
    clicked_sprite = "utility/reset",
    tooltip = {"recursive-blueprints.reset-scanner-counters-settings"},
  }
  local settings_lines = inner_frame2.add{
    direction = "vertical",
    type = "flow"  -- Change the type to "scroll-pane" if the number of counters no longer fit in the frame.
    --type = "scroll-pane",
    --style = "recursive-blueprints-scroll", -- You need to find the suitable style.
    --horizontal_scroll_policy = "never",
    --vertical_scroll_policy = "auto",
  }
  for name, _ in pairs(AreaScanner.get_list_from_filter(0).counters) do
    AreaScannerGUI.add_counter_setting_line(settings_lines, name)
  end

  -- Display current values
  AreaScannerGUI.update_scanner_gui(gui)
  counters_frame.visible = false
  return gui
end

function AreaScannerGUI.add_input_setting_line(element, caption, name, tooltip)
  local flow = element.add{type = "flow"}
  flow.style.vertical_align = "center"
  flow.add{
    type = "label",
    caption = {"", {caption}, ":"},
    tooltip = tooltip
  }
  flow.add{
    type = "sprite-button", style = "recursive-blueprints-slot",
    name = "recursive-blueprints-signal-select-button",
    tags = {type = "input", name = name}
  }
end

function AreaScannerGUI.add_counter_setting_line(element, name)
  local flow = element.add{type = "flow"}
  flow.style.vertical_align = "center"
  flow.add{
    type = "checkbox", state = false, style = "recursive-blueprints-checkbox-minus",
    name = "recursive-blueprints-counter-checkbox",
    tooltip = {"recursive-blueprints.counter-negative-checkbox"},
    enabled = false,
  }
  flow.add{
    type = "sprite-button", style = "recursive-blueprints-slot",
    name = "recursive-blueprints-signal-select-button",
    tags = {type = "output", name = name},
    enabled = false,
  }
  flow.add{
    type = "label",
    caption = {"recursive-blueprints.counter-name-"..name},
    tooltip = {"recursive-blueprints.counter-tooltip-"..name},
  }
end

---Build the "select a signal or constant" gui
---@param element table The sprite button that opened this menu
function AreaScannerGUI.create_signal_gui(element)
  local screen = element.gui.screen
  local primary_gui = screen["recursive-blueprints-scanner"]
  local id = primary_gui.tags["recursive-blueprints-id"]
  local scanner = storage.scanners[id]
  local settings = scanner.settings or AreaScanner.DEFAULT_SCANNER_SETTINGS
  local scan_area = settings.scan_area or AreaScanner.DEFAULT_SCANNER_SETTINGS.scan_area
  local field = element.tags.name
  local field_type = element.tags.type
  local filter_calc = field == "filter" and (not scanner.settings or not scanner.settings.scan_area)

  -- Highlight the button that opened the gui
  AreaScannerGUI.reset_scanner_gui_style(screen)
  element.style = "recursive-blueprints-slot-selected"

  -- Destroy any old version
  if screen["recursive-blueprints-signal"] then
    screen["recursive-blueprints-signal"].destroy()
  end

  -- Place gui slightly to the right of center
  local location = primary_gui.location
  local scale = game.get_player(element.player_index).display_scale
  location.x = location.x + 126 * scale
  location.y = location.y - 60 * scale

  -- Find the previously selected signal.
  local target = {}
  if field_type == "input" then
    local v = scan_area[field]
    if type(v) == "table" then target = v end
  else
    local c = settings.counters or AreaScanner.DEFAULT_SCANNER_SETTINGS.counters
    target = c[field].signal
  end

  -- Heading
  local gui_direction = "vertical"
  if field == "filter" then gui_direction = "horizontal" end
  local gui = screen.add{
    type = "frame",
    name = "recursive-blueprints-signal",
    style = "invisible_frame",
    direction = gui_direction,
    tags = {
      ["recursive-blueprints-id"] = id,
      ["recursive-blueprints-field"] = field,
      ["recursive-blueprints-type"] = field_type,
    }
  }
  gui.location = location
  local signal_select = gui.add{type = "frame", direction = "vertical", visible = not filter_calc}
  GUI_util.add_titlebar(signal_select, gui, {"gui.select-signal"}, "recursive-blueprints-close")
  GUI_util.add_signal_select_frame(signal_select, target)

  if field_type == "input" and field ~= "filter" then
    -- Set a constant
    local set_constant = gui.add{type = "frame", direction = "vertical"}
    GUI_util.add_titlebar(set_constant, gui, {"gui.or-set-a-constant"})
    local inner_frame = set_constant.add{type = "frame", style = "entity_frame", direction = "horizontal"}
    inner_frame.style.vertical_align = "center"

    -- Slider settings
    local maximum_value = 28  -- 10 * log(999)
    local allow_negative = false
    if (field == "x" or field == "y") then
      maximum_value = 74  -- 2 * 10 * log(10000)
      allow_negative = true
    end

    -- Slider
    local slider = inner_frame.add{
      type = "slider",
      name = "recursive-blueprints-slider",
      maximum_value = maximum_value,
    }
    slider.style.top_margin = 8
    slider.style.bottom_margin = 8

    -- Text field
    local textfield = inner_frame.add{
      type = "textfield",
      name = "recursive-blueprints-constant",
      numeric = true,
      allow_negative = allow_negative,
    }
    textfield.style.width = 80
    textfield.style.horizontal_align = "center"
    if type(scan_area[field]) == "table" then
      textfield.text = "0"
    else
      textfield.text = tostring(scan_area[field])
    end
    AreaScannerGUI.copy_text_value(textfield)

    -- Submit button
    local filler = inner_frame.add{type = "empty-widget"}
    filler.style.horizontally_stretchable = true
    inner_frame.add{
      type = "button",
      style = "recursive-blueprints-set-button",
      name = "recursive-blueprints-set-constant",
      caption = {"gui.set"},
    }

  elseif field == "filter" then
    local set_filter = gui.add{type = "frame", direction = "vertical"}
    if filter_calc then
      GUI_util.add_titlebar(set_filter, gui, {""}, "recursive-blueprints-close")
    else
      GUI_util.add_titlebar(set_filter, gui, {"gui.or-set-a-constant"})
    end
    local inner_frame = set_filter.add{type = "frame", style = "entity_frame", direction = "vertical"}
    inner_frame.style.minimal_width = 0
    local options_flow = inner_frame.add{type = "flow", direction = "horizontal"}
    local filters_flow = options_flow.add{type = "flow", direction = "vertical"}
    filters_flow.add{
      type = "label",
      style = "heading_2_label",
      caption = {"recursive-blueprints.heading_label-filters"}
    }
    --options_flow.add{type = "line", direction = "vertical"}
    local counters_flow = options_flow.add{type = "flow", direction = "vertical"}
    counters_flow.style.left_margin = 10
    counters_flow.add{
      type = "label",
      style = "heading_2_label",
      caption = {"recursive-blueprints.heading_label-counters"}
    }

    local filter_list = AreaScanner.get_list_from_filter(scanner.current.filter)
    for _, setting in pairs(AreaScanner.FILTER_MASK_ORDER) do
      if setting.group == "filters" then
        local name = setting.name
        local tooltip = nil
        if name == "blank" then tooltip = {"recursive-blueprints.counter-tooltip-blank"} end
        filters_flow.add{
          type = "checkbox",
          state = filter_list.filters[name] or false,
          caption = {"recursive-blueprints.counter-name-"..name},
          tooltip = tooltip,
          tags = {
            ["recursive-blueprints-filter-checkbox-field"] = name,
            ["recursive-blueprints-filter-checkbox-type"] = "filters"
          }
        }
      elseif setting.group == "counters" then
        local name = setting.name
        counters_flow.add{
          type = "checkbox",
          state = filter_list.counters[name] or false,
          caption = {"recursive-blueprints.counter-name-"..name},
          tooltip = {"recursive-blueprints.counter-tooltip-"..name},
          tags = {
            ["recursive-blueprints-filter-checkbox-field"] = name,
            ["recursive-blueprints-filter-checkbox-type"] = "counters"
          }
        }
      end
    end

    -- Text field
    local filter_end_line = inner_frame.add{type = "flow", direction = "horizontal"}
    filter_end_line.add{type = "empty-widget"} -- needed for set_scanner_value function
    local textfield = filter_end_line.add{
      type = "textfield",
      name = "recursive-blueprints-filter-constant",
      numeric = true,
      allow_negative = true,
    }
    textfield.style.width = 100
    textfield.style.horizontal_align = "center"
    textfield.text = tostring(scanner.current.filter)
    -- Submit button
    local cap = {"gui.set"}
    if filter_calc then cap = {"gui.cancel"} end
    local filler = filter_end_line.add{type = "empty-widget"}
    filler.style.horizontally_stretchable = true
    filter_end_line.add{
      type = "button",
      style = "recursive-blueprints-set-button",
      name = "recursive-blueprints-set-constant",
      caption = cap,
    }
  end

  return gui
end

-- Turn off highlighted scanner button
function AreaScannerGUI.reset_scanner_gui_style(screen)
  local gui = screen["recursive-blueprints-scanner"]
  if not gui then return end
  local input_flow = gui.children[1].children[2].children[2].children[1].children[2]
  for i = 1, #input_flow.children do
    input_flow.children[i].children[2].style = "recursive-blueprints-slot"
  end
  local settings_lines = gui.children[2].children[2].children[2]
  for i = 1, #settings_lines.children do
    settings_lines.children[i].children[2].style = "recursive-blueprints-slot"
  end
end

function AreaScannerGUI.destroy_gui(element)
    local gui = GUI_util.get_root_element(element)
    -- Destroy dependent gui
    local screen = gui.gui.screen
    if gui.name == "recursive-blueprints-scanner" and screen["recursive-blueprints-signal"] then
      screen["recursive-blueprints-signal"].destroy()
    end
    -- Destroy gui
    gui.destroy()
    AreaScannerGUI.reset_scanner_gui_style(screen)
end

-- Copy constant value from signal gui to scanner gui
function AreaScannerGUI.set_scanner_value(element)
  local screen = element.gui.screen
  local scanner_gui = screen["recursive-blueprints-scanner"]
  if not scanner_gui then return end
  local scanner = storage.scanners[scanner_gui.tags["recursive-blueprints-id"]]
  local signal_gui = screen["recursive-blueprints-signal"]
  local key = signal_gui.tags["recursive-blueprints-field"]
  if signal_gui.tags["recursive-blueprints-type"] ~= "input" then return end
  if not scanner.settings or not scanner.settings.scan_area then
    AreaScannerGUI.update_scanner_gui(scanner_gui)
    AreaScannerGUI.reset_scanner_gui_style(screen)
    signal_gui.destroy()
    return
  end

  local value = tonumber(element.parent.children[2].text) or 0
  value = AreaScanner.sanitize_area(key, value)
  scanner.settings.scan_area[key] = value
  AreaScanner.check_input_signals(scanner)

  -- Run a scan if the area has changed
  if scanner.previous[key] ~= value then
    scanner.previous[key] = value
    scanner.current[key] = value
    AreaScanner.scan_resources(scanner)
  end

  -- The user might have changed a signal without changing the area,
  -- so always refresh the gui.
  AreaScannerGUI.update_scanner_gui(scanner_gui)
  AreaScannerGUI.reset_scanner_gui_style(screen)

  -- Close signal gui
  signal_gui.destroy()
end

-- Copy signal from signal gui to scanner gui
function AreaScannerGUI.set_scanner_signal(element)
  local screen = element.gui.screen
  local signal_gui = screen["recursive-blueprints-signal"]
  local scanner_gui = screen["recursive-blueprints-scanner"]
  if not scanner_gui then return end
  local scanner = storage.scanners[scanner_gui.tags["recursive-blueprints-id"]]
  local settings = scanner.settings
  if not settings then
    AreaScannerGUI.update_scanner_gui(scanner_gui)
    AreaScannerGUI.reset_scanner_gui_style(screen)
    signal_gui.destroy()
    return
  end
  local key = signal_gui.tags["recursive-blueprints-field"]
  local key_type = signal_gui.tags["recursive-blueprints-type"]

  if key_type == "input" and settings.scan_area then
    settings.scan_area[key] = element.tags["recursive-blueprints-signal"]
    scanner.network_imput = true
  elseif settings.counters then
    settings.counters[key].signal = element.tags["recursive-blueprints-signal"]
    AreaScanner.scan_resources(scanner)
  end
  AreaScannerGUI.update_scanner_gui(scanner_gui)
  AreaScannerGUI.reset_scanner_gui_style(screen)

  -- Close signal gui
  signal_gui.destroy()
end

-- Copy value from slider to text field
function AreaScannerGUI.copy_slider_value(element)
  local gui = GUI_util.get_root_element(element)
  local field = gui.tags["recursive-blueprints-field"]
  local value = 0
  if field == 'x' or field == 'y' then
    -- 1-9(+1) 10-90(+10) 100-900(+100) 1000-10000(+1000)
    if element.slider_value < 10 then
      value = 1000 * (element.slider_value - 10)
    elseif element.slider_value < 19 then
      value = 100 * (element.slider_value - 19)
    elseif element.slider_value < 28 then
      value = 10 * (element.slider_value - 28)
    elseif element.slider_value < 47 then
      value = element.slider_value - 37
    elseif element.slider_value < 56 then
      value = 10 * (element.slider_value - 46)
    elseif element.slider_value < 65 then
      value = 100 * (element.slider_value - 55)
    else
      value = 1000 * (element.slider_value - 64)
    end
  else
    -- 1-10(+1) 20-100(+10) 200-999(+100)
    if element.slider_value < 11 then
      value = element.slider_value
    elseif element.slider_value < 20 then
      value = 10 * (element.slider_value - 9)
    elseif element.slider_value < 28 then
      value = 100 * (element.slider_value - 18)
    else
      value = 999
    end
  end
  element.parent["recursive-blueprints-constant"].text = tostring(value)
end

-- Copy value from text field to slider
function AreaScannerGUI.copy_text_value(element)
  local gui = GUI_util.get_root_element(element)
  local field = gui.tags["recursive-blueprints-field"]
  local text_value = tonumber(element.text) or 0
  local value = 0
  if field == 'x' or field == 'y' then
    if text_value <= -1000 then
      value = math.floor(text_value / 1000 + 10.5)
    elseif text_value <= -100 then
      value = math.floor(text_value / 100 + 19.5)
    elseif text_value <= -10 then
      value = math.floor(text_value / 10 + 28.5)
    elseif text_value <= 10 then
      value = math.floor(text_value + 37.5)
    elseif text_value <= 100 then
      value = math.floor(text_value / 10 + 46.5)
    elseif text_value <= 1000 then
      value = math.floor(text_value / 100 + 55.5)
    else
      value = math.floor(text_value / 1000 + 64.5)
    end
  else
    if text_value <= 10 then
      value = text_value
    elseif text_value <= 100 then
      value = math.floor(text_value / 10 + 9.5)
    elseif text_value < 999 then
      value = math.floor(text_value / 100 + 18.5)
    else
      value = 28
    end
  end
  element.parent["recursive-blueprints-slider"].slider_value = value
end

-- Copy value from filter checkboxes to text field
function AreaScannerGUI.copy_filter_value(element)
  local settings = {filters = {}, counters = {}}
  for _, flow in pairs(element.parent.parent.children) do
    for _, c_element in pairs(flow.children) do
      if c_element.type == "checkbox" then
        local f_type = c_element.tags["recursive-blueprints-filter-checkbox-type"]
        local f_name = c_element.tags["recursive-blueprints-filter-checkbox-field"]
        settings[f_type][f_name] = c_element.state
      end
    end
  end
  local textfield = element.parent.parent.parent.children[2].children[2]
  textfield.text = tostring(AreaScanner.get_filter_from_list(settings))
end

-- Copy value from text field to filter checkboxes
function AreaScannerGUI.copy_filter_text_value(element)
  local f_list = AreaScanner.get_list_from_filter(tonumber(element.text) or 0)
  for _, flow in pairs(element.parent.parent.children[1].children) do
    for _, c_element in pairs(flow.children) do
      if c_element.type == "checkbox" then
        local f_type = c_element.tags["recursive-blueprints-filter-checkbox-type"]
        local f_name = c_element.tags["recursive-blueprints-filter-checkbox-field"]
        c_element.state = f_list[f_type][f_name]
      end
    end
  end
end

function AreaScannerGUI.counter_checkbox_change(element)
  local screen = element.gui.screen
  local scanner_gui = screen["recursive-blueprints-scanner"]
  if not scanner_gui then return end
  local scanner = storage.scanners[scanner_gui.tags["recursive-blueprints-id"]]
  local key = element.parent.children[2].tags.name
  scanner.settings.counters[key].is_negative = element.state
  AreaScanner.scan_resources(scanner)
  AreaScannerGUI.update_scanner_gui(scanner_gui)
end

function AreaScannerGUI.toggle_counter_settings_frame(element)
  local gui = GUI_util.get_root_element(element)
  gui.children[2].visible = not gui.children[2].visible
end

function AreaScannerGUI.reset_counter_settings(element)
  local scanner_gui = GUI_util.get_root_element(element)
  local scanner = storage.scanners[scanner_gui.tags["recursive-blueprints-id"]]
  if not scanner.settings then return end
  scanner.settings.counters = nil
  --[[
  for name, counter in pairs(AreaScanner.DEFAULT_SCANNER_SETTINGS.counters) do
    scanner.settings.counters[name].is_negative = counter.is_negative
    scanner.settings.counters[name].signal = {type = counter.signal.type, name = counter.signal.name, quality="normal", comparator="="}
  end
  ]]
  AreaScanner.scan_resources(scanner)
  AreaScannerGUI.update_scanner_gui(scanner_gui)
end

-- Display all constant-combinator output signals in the gui
function AreaScannerGUI.update_scanner_output(output_flow, scanner)
  while #output_flow.children > 0 do output_flow.children[1].destroy() end
  local output_behavior = AreaScanner.get_or_create_output_behavior(scanner)
  if #output_behavior.sections < 1 then return end
  local section = output_behavior.sections[1]
  if section then
    local slots = section.filters_count
    for i = 1, slots, 10 do
      local row = output_flow.add{type = "flow", style = "packed_horizontal_flow"}
      for j = 0, 9 do
        if i+j <= slots then
          local signal = section.get_slot(i+j)
          if signal and signal.value and signal.value.name then
            local button = row.add{
              type = "sprite-button",
              style = "recursive-blueprints-output",
              number = signal.min,
              sprite = GUI_util.get_signal_sprite(signal.value),
              elem_tooltip = RB_util.get_elem_from_signal(signal.value),
            }
            local q = signal.value.quality
            if q and storage.quality_levels[q] > 0 then
              local q_flow = button.add{type = "flow"}
              q_flow.style.vertical_align="bottom"
              q_flow.style.size = 32
              local q_sprite = q_flow.add{
                type = "sprite",
                sprite = "quality/".. q,
              }
              q_sprite.style.stretch_image_to_widget_size = true
              q_sprite.style.size = 16
            end
          else
            row.add{
              type = "sprite-button",
              style = "recursive-blueprints-output",
            }
          end
        end
      end
    end
  end
end

-- Populate gui with the latest data
function AreaScannerGUI.update_scanner_gui(gui)
  local scanner = storage.scanners[gui.tags["recursive-blueprints-id"]]
  if not scanner then return end
  if not scanner.entity.valid then return end

  -- Update area dimensions
  local settings = scanner.settings or AreaScanner.DEFAULT_SCANNER_SETTINGS
  local scan_area = settings.scan_area or AreaScanner.DEFAULT_SCANNER_SETTINGS.scan_area
  local input_flow = gui.children[1].children[2].children[2].children[1].children[2]
  local numbers = scanner.current
  if not numbers then numbers = {} end
  GUI_util.set_slot_button(input_flow.children[1].children[2], scan_area.x, numbers.x)
  GUI_util.set_slot_button(input_flow.children[2].children[2], scan_area.y, numbers.y)
  GUI_util.set_slot_button(input_flow.children[3].children[2], scan_area.width, numbers.width)
  GUI_util.set_slot_button(input_flow.children[4].children[2], scan_area.height, numbers.height)
  GUI_util.set_slot_button(input_flow.children[5].children[2], scan_area.filter, numbers.filter)

  if not scanner.settings or not scanner.settings.scan_area then
    for i=1, 4 do input_flow.children[i].children[2].enabled = false end
  end

  -- Update minimap
  scan_area = scanner.current
  local c, s = RB_util.area_find_center_and_size(AreaScanner.get_scan_area(scanner.entity.position, scan_area))
  local minimap = gui.children[1].children[2].children[2].children[2].children[1]
  minimap.position = c
  local largest = math.max(s[1], s[2])
  if largest == 0 then largest = 32 end
  minimap.zoom = 8192 / largest * gui.gui.player.display_scale
  minimap.style.natural_width = s[1] / largest * 256
  minimap.style.natural_height = s[2] / largest * 256

  AreaScannerGUI.update_scanner_output(gui.children[1].children[2].children[5].children[1], scanner)

  if not gui.children[2].visible then return end
  local settings_lines = gui.children[2].children[2].children[2]
  local counters = settings.counters or AreaScanner.DEFAULT_SCANNER_SETTINGS.counters
  for i = 1, #settings_lines.children do
    local sprite_button = settings_lines.children[i].children[2]
    GUI_util.set_slot_button(sprite_button, counters[sprite_button.tags.name].signal)
    settings_lines.children[i].children[1].state = counters[sprite_button.tags.name].is_negative or false
  end
end

return AreaScannerGUI
