local accountRoles = {}

CreateThread(function()
	local accountRolesFromDb = MySQL.query.await("SELECT name FROM account_roles")
	for _, role in pairs(accountRolesFromDb) do
		table.insert(accountRoles, { value = role.name })
	end
	table.insert(accountRoles, { value = "none" })
end)

lib.addCommand("oxgroups", {
	help = 'Open the OxGroups menu',
	restricted = "group.admin"
}, function(source)
	local groups = {}
	for _, group in pairs(GlobalState.groups) do
		local oxGroup = Ox.GetGroup(group)
		local newGrades = {}
		for gradeId, label in pairs(oxGroup.grades) do
			local accountRole = oxGroup.accountRoles[tostring(gradeId)] or "none"
			table.insert(newGrades, {
				id = gradeId,
				label = label,
				accountRole = accountRole,
			})
		end
		oxGroup.grades = newGrades
		oxGroup.hasAccount = oxGroup.hasAccount == 1
		table.insert(groups, oxGroup)
	end

	TriggerClientEvent("ceeb_oxgroups:open", source, groups, accountRoles)
end)


RegisterNetEvent("ceeb_oxgroups:deleteGroup", function(groupName, deleteAccount)
	local source = source
	if not IsPlayerAceAllowed(source, "command.oxgroups") then return end
	if deleteAccount then
		MySQL.query.await("DELETE FROM accounts WHERE `group` = ? AND isDefault = true", { groupName })
	end
	Ox.DeleteGroup(groupName)
	TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = "Group deleted" })
end)

RegisterNetEvent("ceeb_oxgroups:createGroup", function(newGroup)
	local source = source
	if not IsPlayerAceAllowed(source, "command.oxgroups") then return end
	local formattedGrades = {}
	for _, grade in pairs(newGroup.grades) do
		formattedGrades[grade.id] = {
			label = grade.label,
		}
		if grade.accountRole ~= "none" then
			formattedGrades[grade.id].accountRole = grade.accountRole
		end
	end

	Ox.CreateGroup({
		name = newGroup.name,
		label = newGroup.label,
		grades = formattedGrades,
		type = newGroup.type,
		hasAccount = newGroup.hasAccount,
	})
	TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = "Group created" })
end)
