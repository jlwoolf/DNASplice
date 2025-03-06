local config = SMODS.current_mod.config

---@type 'deck'|'tag'
local LAST_SELECTED_CONFIG_TAB = "deck"
local TAG_KEY = "tag_dna_splice"
local DECK_KEY = "b_dna_splice"

---callback for the tag config enabled toggle
---@param enabled any
local function toggle_tag(enabled)
	local tag = SMODS.Tags[TAG_KEY]
	if enabled then
		G.P_TAGS[TAG_KEY] = tag
		SMODS.insert_pool(G.P_CENTER_POOLS[tag.set], tag)
	else
		G.P_TAGS[TAG_KEY] = nil
		SMODS.remove_pool(G.P_CENTER_POOLS[tag.set], tag)
	end
end

---callback for the deck config enabled toggle
---@param enabled any
local function toggle_deck(enabled)
	local deck = SMODS.Centers[DECK_KEY]
	deck.omit = not enabled
end

---creates the toggles for the config tab
---@param variant 'deck'|'tag'
---@return table
local function create_config_toggles(variant)
	local callback = {
		tag = toggle_tag,
		deck = toggle_deck,
	}

	return {
		n = G.UIT.C,
		config = {
			align = "cm",
			r = 0.2,
			colour = G.C.CLEAR,
			emboss = 0.05,
			padding = 0.2,
			minw = 4,
		},
		nodes = {
			create_toggle({
				label = "Enabled",
				ref_table = config and config[variant] or {},
				ref_value = "enabled",
				callback = callback[variant],
				w = 1,
			}),
			create_toggle({
				label = "Negative Joker",
				w = 1,
				ref_table = config and config[variant] or {},
				ref_value = "negative",
			}),
		},
	}
end

---creates the tag node for the tag tab in the config
---@return table
local function create_dna_tag_node()
	--- copied over from Tag:generate_UI but removed dependencies that come from
	--- actual tag definition. This way sprite can render without tag enabled
	local tag_sprite = Sprite(0, 0, 0.8, 0.8, G.ASSET_ATLAS["dna_splice_tag"], { x = 0, y = 0 })
	tag_sprite.T.scale = 1
	tag_sprite.float = true
	tag_sprite.states.hover.can = true
	tag_sprite.states.drag.can = false
	tag_sprite.states.collide.can = true
	tag_sprite.config = { force_focus = true }

	tag_sprite:define_draw_steps({
		{ shader = "dissolve", shadow_height = 0.05 },
		{ shader = "dissolve" },
	})

	tag_sprite.hover = function(_self)
		if not G.CONTROLLER.dragging.target or G.CONTROLLER.using_touch then
			if not _self.hovering and _self.states.visible then
				_self.hovering = true
				if _self == tag_sprite then
					_self.hover_tilt = 3
					_self:juice_up(0.05, 0.02)
					play_sound("paper1", math.random() * 0.1 + 0.55, 0.42)
					play_sound("tarot2", math.random() * 0.1 + 0.55, 0.09)
				end

				Node.hover(_self)
				if _self.children.alert then
					_self.children.alert:remove()
					_self.children.alert = nil
					G:save_progress()
				end
			end
		end
	end

	tag_sprite.stop_hover = function(_self)
		_self.hovering = false
		Node.stop_hover(_self)
		_self.hover_tilt = 0
	end

	local tag_sprite_tab = {
		n = G.UIT.C,
		config = { align = "cm" },
		nodes = {
			{
				n = G.UIT.O,
				config = {
					w = 0.8,
					h = 0.8,
					colour = G.C.BLUE,
					object = tag_sprite,
					focus_with_object = true,
				},
			},
		},
	}

	return {
		n = G.UIT.C,
		config = { align = "cm", padding = 0.1 },
		nodes = {
			tag_sprite_tab,
		},
	}
end

---creates the card node for the card tab in the config
---@return table
local function create_dna_card_node()
	local area = CardArea(
		G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2,
		G.ROOM.T.h,
		G.CARD_W,
		G.CARD_H,
		{ card_limit = 5, type = "deck", highlight_limit = 0, deck_height = 0.75, thin_draw = 1 }
	)

	G.GAME.viewed_back = Back(SMODS.Centers[DECK_KEY])

	for i = 1, 10 do
		local card = Card(
			G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2,
			G.ROOM.T.h,
			G.CARD_W,
			G.CARD_H,
			pseudorandom_element(G.P_CARDS),
			G.P_CENTERS.c_base,
			{ playing_card = i, viewed_back = true }
		)
		card.sprite_facing = "back"
		card.facing = "back"
		area:emplace(card)
	end

	return { n = G.UIT.O, config = { object = area } }
end

---creates a config tab of a specified variant
---@param variant 'deck'|'tag'
---@return table
local function create_config_tab(variant)
	local node_functions = {
		deck = create_dna_card_node,
		tag = create_dna_tag_node,
	}

	local label = {
		deck = "Deck",
		tag = "Tag",
	}

	return {
		label = label[variant],
		chosen = LAST_SELECTED_CONFIG_TAB == variant or false,
		tab_definition_function = function(...)
			LAST_SELECTED_CONFIG_TAB = variant

			return {
				n = G.UIT.ROOT,
				config = { align = "cm", padding = 0.05, colour = G.C.CLEAR },
				nodes = {
					{
						n = G.UIT.R,
						config = { align = "cm", colour = G.C.CLEAR, r = 0.2 },
						nodes = {
							{
								n = G.UIT.C,
								config = { align = "cm", padding = 0 },
								nodes = { node_functions[variant]() },
							},
							create_config_toggles(variant),
						},
					},
				},
			}
		end,
	}
end

---the config tab for the mod
---@return table
local function config_tab()
	SMODS.LAST_SELECTED_MOD_TAB = "mod_desc"
	G.FUNCS.overlay_menu({
		definition = (create_UIBox_generic_options({
			back_func = "openModUI_DNASplice",
			contents = {
				{
					n = G.UIT.R,
					config = {
						padding = 0,
						align = "tm",
					},
					nodes = {
						create_tabs({
							snap_to_nav = true,
							colour = G.C.MULT,
							tab_alignment = "tm",
							tabs = { create_config_tab("deck"), create_config_tab("tag") },
						}),
					},
				},
			},
		})),
	})
	return {}
end

SMODS.current_mod.config_tab = config_tab

SMODS.Atlas({
	key = "dna_splice_tag",
	path = "dna_splice_tag.png",
	px = 34,
	py = 34,
})

SMODS.Tag({
	atlas = "dna_splice_tag",
	config = {
		type = "store_joker_create",
	},
	discovered = true,
	key = "dna_splice",
	in_pool = function()
		return config and config["tag"]["enabled"] or false
	end,
	loc_txt = {
		name = "DNA Splice Tag",
		text = {
			"Shop has a free",
			"{V:1}#1#{}{C:attention}DNA Joker{}",
		},
	},
	name = "DNA Splice Tag",
	prefix_config = {
		key = {
			mod = false,
		},
	},
	apply = function(self, tag, context)
		if tag.triggered then
			return
		end

		if tag.config.type ~= context.type then
			return
		end

		local dna_card = create_card("Joker", context.area, nil, nil, nil, nil, "j_dna")
		create_shop_card_ui(dna_card, "Joker", context.area)

		dna_card.states.visible = false
		tag:yep("+", G.C.BLUE, function()
			dna_card:start_materialize()

			local negative = config and config.tag and config.tag.negative
			if negative then
				dna_card:set_edition({ negative = true }, true)
			end

			dna_card.ability.couponed = true
			dna_card:set_cost()
			return true
		end)

		G.shop_jokers:emplace(dna_card)
		dna_card:juice_up()

		tag.triggered = true
	end,
	inject = function(self)
		local enabled = config and config.tag and config.tag.enabled

		if enabled then
			G.P_TAGS[self.key] = self
			SMODS.insert_pool(G.P_CENTER_POOLS[self.set], self)
		end
	end,
	loc_vars = function(self, info_queue, card)
		local negative = config and config.tag and config.tag.negative
		if negative then
			info_queue[#info_queue + 1] = G.P_CENTERS.e_negative
		end

		info_queue[#info_queue + 1] = G.P_CENTERS.j_dna
		return {
			vars = {
				negative and "Negative " or "",
				colours = {
					G.C.DARK_EDITION,
				},
			},
		}
	end,
})

SMODS.Atlas({
	key = "dna_splice_deck",
	path = "dna_splice_deck.png",
	px = 71,
	py = 95,
})

SMODS.Back({
	atlas = "dna_splice_deck",
	key = "dna_splice",
	name = "DNA Splice Deck",
	loc_txt = {
		name = "DNA Splice Deck",
		text = {
			"Start with a free",
			"{V:1,T:e_negative}#1#{}{C:attention,T:j_dna}DNA Joker{}",
		},
	},
	pos = { x = 0, y = 0 },
	prefix_config = {
		key = {
			mod = false,
		},
	},
	apply = function(self, back)
		delay(0.4)
		G.E_MANAGER:add_event(Event({
			func = function()
				local dna_card = create_card("Joker", G.jokers, nil, nil, nil, nil, "j_dna", "deck")
				local negative = config and config.deck and config.deck.negative
				if negative then
					dna_card:set_edition({ negative = true }, true)
				end

				dna_card:add_to_deck()
				G.jokers:emplace(dna_card)
				dna_card:start_materialize()
				return true
			end,
		}))
	end,
	inject = function(self)
		local enabled = config and config.deck and config.deck.enabled
		self.omit = not enabled

		SMODS.Back.super.inject(self)
	end,
	loc_vars = function()
		local negative = config and config.deck and config.deck.negative
		return {
			vars = {
				negative and "Negative " or "",
				colours = {
					G.C.DARK_EDITION,
				},
			},
		}
	end,
})
