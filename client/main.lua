local cacheGroups = {}
local cacheAccountRoles = {}
local menuId = "ceeb_oxgroups"

RegisterNetEvent("ceeb_oxgroups:open", function(groups, accountRoles)
	cacheGroups = groups
	cacheAccountRoles = accountRoles
	ShowMainMenu()
end)

function GetGroup(groupName)
	for _, group in pairs(cacheGroups) do
		if group.name == groupName then
			return group
		end
	end
	return false
end

function CreateNewGroup()
	local input = lib.inputDialog('Create a new group', {
		{ type = 'input',    label = 'Label',                  placeholder = "Los Santos Police Dept",      description = 'The label of the group', required = true },
		{ type = 'input',    label = 'Name',                   placeholder = "lspd",                        description = 'The name of the group',  required = true },
		{ type = 'input',    label = 'Type',                   placeholder = "job",                         description = 'The type of the group',  required = true },
		{ type = 'checkbox', label = 'Create default account', description = 'If the group need an account' }
	})

	if not input then return end
	local newGroup = {
		label = input[1],
		name = input[2],
		type = input[3],
		hasAccount = input[4],
		grades = {}
	}

	ShowMainMenuForNewGroup(newGroup)
end

function ShowMainMenu()
	local options = {}
	for _, group in pairs(cacheGroups) do
		table.insert(options, {
			label = group.label,
			args = {
				group = group.name
			}
		})
	end
	table.insert(options, {
		label = "Create new group",
		args = {
			create = true
		},
		icon = "fas fa-plus",
	})
	lib.registerMenu({
		id       = menuId,
		title    = 'Ox Groups',
		position = 'top-left',
		options  = options,
	}, function(selected, scrollIndex, args)
		if args.create then
			CreateNewGroup()
			return
		end

		ShowMainMenuForGroup(args.group)
	end)
	lib.showMenu(menuId)
end

function ShowMainMenuForNewGroup(newGroup)
	local options = {
		{
			label = ("Label: %s"):format(newGroup.label),
			close = false,
			icon = "fas fa-tag"
		},
		{
			label = ("Name: %s"):format(newGroup.name),
			close = false,
			icon = "fas fa-id-card"
		},
		{
			label = ("Type: %s"):format(newGroup.type),
			close = false,
			icon = "fas fa-id-card"
		},
		{
			label = ("Has account: %s"):format(newGroup.hasAccount and "Yes" or "No"),
			close = false,
			icon = "fas fa-bank"
		},
		{
			label = ("Show grades (%s)"):format(#newGroup.grades),
			args = {
				showGrades = true
			},
			icon = "fas fa-list"
		},
		{
			label = "Create group",
			icon = "fas fa-check",
			args = {
				createGroup = true
			}
		}
	}
	lib.registerMenu({
		id       = menuId,
		title    = 'New group',
		position = 'top-left',
		options  = options,
		onClose  = function()
			ShowMainMenu()
		end
	}, function(selected, scrollIndex, args)
		if args.showGrades then
			ShowGradeMenuForNewGroup(newGroup)
			return
		elseif args.createGroup then
			if #newGroup.grades == 0 then
				lib.notify({ type = "error", description = "You need to add at least one grade." })
				ShowMainMenuForNewGroup(newGroup)
				return
			end
			local lastGrade = 0
			for _, data in pairs(newGroup.grades) do
				if data.id ~= lastGrade + 1 then
					lib.notify({
						type = "error",
						description = "You are missing a grade, it needs to be from 1 and increment by 1"
					})
					ShowMainMenuForNewGroup(newGroup)
					return
				end
				lastGrade = data.id
			end
			TriggerServerEvent("ceeb_oxgroups:createGroup", newGroup)
		end
	end)
	lib.showMenu(menuId)
end

function ShowGradeMenuForNewGroup(newGroup)
	local options = {}
	for _, data in pairs(newGroup.grades) do
		table.insert(options, {
			label = data.label,
			args = {
				grade = data.id
			}
		})
	end
	table.insert(options, {
		label = "Add grade",
		icon = "fas fa-plus",
		args = {
			addGrade = true
		}
	})
	lib.registerMenu({
		id       = menuId,
		title    = 'Grades',
		position = 'top-left',
		options  = options,
		onClose  = function()
			ShowMainMenuForNewGroup(newGroup)
		end
	}, function(selected, scrollIndex, args)
		if args.addGrade then
			local input = lib.inputDialog('Add grade', {
				{ type = 'number', label = 'Id',           placeholder = "1",           description = 'The id of the grade',                                required = true },
				{ type = 'input',  label = 'Label',        placeholder = "Cadet",       description = 'The label of the grade',                             required = true },
				{ type = 'select', label = 'Account role', options = cacheAccountRoles, description = 'The account role of the grade for the bank account', required = true }

			})
			if not input then
				ShowGradeMenuForNewGroup(newGroup)
				return
			end
			for _, data in pairs(newGroup.grades) do
				if data.id == input[1] then
					lib.notify({ type = "error", description = "Grade already exists." })
					ShowGradeMenuForNewGroup(newGroup)
					return
				end
			end
			table.insert(newGroup.grades, { id = input[1], label = input[2], accountRole = input[3] })
			table.sort(newGroup.grades, function(a, b) return a.id < b.id end)
			ShowGradeMenuForNewGroup(newGroup)
			return
		else
			ShowGradeEditForNewGroup(newGroup, args.grade)
		end
	end)
	lib.showMenu(menuId)
end

function ShowGradeEditForNewGroup(newGroup, selectedGradeId)
	local selectedGrade
	for _, data in pairs(newGroup.grades) do
		if data.id == selectedGradeId then
			selectedGrade = data
			break
		end
	end
	local options = {
		{
			label = ("Id: %s"):format(selectedGrade.id),
			close = false,
			icon = "fas fa-id-card"
		},
		{
			label = ("Label: %s"):format(selectedGrade.label),
			close = false,
			icon = "fas fa-tag"
		},
		{
			label = ("Account role: %s"):format(selectedGrade.accountRole),
			close = false,
			icon = "fas fa-user-tag"
		},
		{
			label = "Edit grade",
			icon = "fas fa-edit",
			args = {
				editGrade = true
			}
		},
		{
			label = "Delete grade",
			icon = "fas fa-trash",
			args = {
				deleteGrade = true
			}
		}
	}
	lib.registerMenu({
		id       = menuId,
		title    = 'Grade',
		position = 'top-left',
		options  = options,
		onClose  = function()
			ShowGradeMenuForNewGroup(newGroup)
		end
	}, function(selected, scrollIndex, args)
		if args.editGrade then
			local input = lib.inputDialog('Edit grade', {
				{ type = 'number', label = 'Id',           default = selectedGrade.id,    placeholder = args.editGrade,                  description = 'The id of the grade',                                required = true },
				{ type = 'input',  label = 'Label',        default = selectedGrade.label, placeholder = newGroup.grades[args.editGrade], description = 'The label of the grade',                             required = true },
				{ type = 'select', label = 'Account role', options = cacheAccountRoles,   default = selectedGrade.accountRole,           description = 'The account role of the grade for the bank account', required = true }
			})
			if not input then
				ShowGradeEditForNewGroup(newGroup, args.editGrade)
				return
			end
			if selectedGrade.id ~= input[1] then
				for _, data in pairs(newGroup.grades) do
					if data.id == input[1] then
						lib.notify({ type = "error", description = ("Grade %s already exists."):format(input[1]) })
						ShowGradeEditForNewGroup(newGroup, selectedGrade.id)
						return
					end
				end
			end
			for key, data in pairs(newGroup.grades) do
				if data.id == selectedGrade.id then
					table.remove(newGroup.grades, key)
					break
				end
			end
			table.insert(newGroup.grades, { id = input[1], label = input[2], accountRole = input[3] })
			table.sort(newGroup.grades, function(a, b) return a.id < b.id end)
			ShowGradeMenuForNewGroup(newGroup)
			return
		end

		if args.deleteGrade then
			for key, data in pairs(newGroup.grades) do
				if data.id == selectedGrade.id then
					table.remove(newGroup.grades, key)
					break
				end
			end
			ShowGradeMenuForNewGroup(newGroup)
			return
		end
	end)
	lib.showMenu(menuId)
end

function ShowMainMenuForGroup(groupName)
	local group = GetGroup(groupName)
	if not group then
		lib.notify({ type = "error", description = "Invalid group." })
		return
	end

	local options = {
		{
			label = ("Label: %s"):format(group.label),
			close = false,
			icon = "fas fa-tag"
		},
		{
			label = ("Name: %s"):format(group.name),
			close = false,
			icon = "fas fa-id-card"
		},
		{
			label = ("Type: %s"):format(group.type),
			close = false,
			icon = "fas fa-id-card"
		},
		{
			label = ("Has account: %s"):format(group.hasAccount and "Yes" or "No"),
			close = false,
			icon = "fas fa-bank"
		},
		{
			label = ("Show grades (%s)"):format(#group.grades),
			args = {
				group = group.name,
				showGrades = true
			},
			icon = "fas fa-list",
		},
		{
			label = "Delete group",
			args = {
				group = group.name,
				delete = true
			},
			icon = "fas fa-trash",
		}
	}

	lib.registerMenu({
		id       = menuId,
		title    = group.label,
		position = 'top-left',
		options  = options,
		onClose  = function()
			ShowMainMenu()
		end
	}, function(selected, scrollIndex, args)
		if args.showGrades then
			ShowGradeMenuForGroup(args.group)
			return
		end

		if args.delete then
			local alert = lib.alertDialog({
				header = ("Delete %s"):format(group.label),
				content = 'Are you sure you want to delete this group?',
				centered = true,
				cancel = true
			})
			if alert ~= "confirm" then return end

			alert = lib.alertDialog({
				header = ("Delete %s"):format(group.label),
				content = 'Do you want also to delete the account (if exists)?',
				centered = true,
				cancel = true,
				labels = {
					confirm = "Delete account",
					cancel = "Keep account"
				}
			})
			local deleteAccount = alert == "confirm"
			TriggerServerEvent("ceeb_oxgroups:deleteGroup", args.group, deleteAccount)
		end
	end)
	lib.showMenu(menuId)
end

function ShowGradeMenuForGroup(groupName)
	local group = GetGroup(groupName)
	if not group then
		lib.notify({ type = "error", description = "Invalid group." })
		return
	end
	local options = {}
	for _, grade in pairs(group.grades) do
		table.insert(options, {
			label = grade.label,
			args = {
				gradeId = grade.id
			}
		})
	end
	lib.registerMenu({
		id       = menuId,
		title    = 'Grades',
		position = 'top-left',
		options  = options,
		onClose  = function()
			ShowMainMenuForGroup(groupName)
		end
	}, function(selected, scrollIndex, args)
		ShowGradeEditForGroup(groupName, args.gradeId)
	end)
	lib.showMenu(menuId)
end

function ShowGradeEditForGroup(groupName, gradeId)
	local group = GetGroup(groupName)
	if not group then
		lib.notify({ type = "error", description = "Invalid group." })
		return
	end
	local grade
	for _, data in pairs(group.grades) do
		if data.id == gradeId then
			grade = data
			break
		end
	end
	if not grade then
		lib.notify({ type = "error", description = "Invalid grade." })
		return
	end
	local options = {
		{
			label = ("Id: %s"):format(grade.id),
			close = false,
			icon = "fas fa-id-card"
		},
		{
			label = ("Label: %s"):format(grade.label),
			close = false,
			icon = "fas fa-tag"
		},
		{
			label = ("Account role: %s"):format(grade.accountRole),
			close = false,
			icon = "fas fa-user-tag"
		},
	}
	lib.registerMenu({
		id       = menuId,
		title    = 'Grade',
		position = 'top-left',
		options  = options,
		onClose  = function()
			ShowGradeMenuForGroup(groupName)
		end
	})
	lib.showMenu(menuId)
end
