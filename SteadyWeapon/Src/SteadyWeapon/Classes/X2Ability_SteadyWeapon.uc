// This is an Unreal Script
class X2Ability_SteadyWeapon extends X2Ability config(GameData_SteadyWeapon); // Find the related ini in the config section above

// Out config variables that we will pull rom the config file
var config int STEADY_WEAPON_AIM_BONUS; // Get aim bonus amount from config file

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(AddSteadyWeaponAbility());

	return Templates;
}

static function X2AbilityTemplate AddSteadyWeaponAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2Condition_UnitProperty PropertyCondition;
	local X2AbilityTrigger_PlayerInput InputTrigger;
	local X2Effect_SteadyWeapon SteadyWeaponEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'SteadyWeapon');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch"; // I can't draw, use overwatch icon for now
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.OVERWATCH_PRIORITY; // Where ability gets placed on the tactical UI bar
	Template.bDisplayInUITooltip = false; // I have no idea what this does actually

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.bShowActivation = true; // show fly text
	Template.bSkipFireAction = true; // no fire animation
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bConsumeAllPoints = true; // End turn when used
	Template.AbilityCosts.AddItem(ActionPointCost);

	PropertyCondition = new class'X2Condition_UnitProperty';	
	PropertyCondition.ExcludeDead = true;                           // Can't use this while ded
	PropertyCondition.ExcludeFriendlyToSource = false;              // Self targeted
	Template.AbilityShooterConditions.AddItem(PropertyCondition);

	Template.AbilityToHitCalc = default.DeadEye; // Always hit
	Template.Hostility = eHostility_Defensive; // Don't break concealment
	Template.AbilityTargetStyle = default.SelfTarget; // Self target

	InputTrigger = new class'X2AbilityTrigger_PlayerInput'; // Player needs to trigger it
	Template.AbilityTriggers.AddItem(InputTrigger);

	SteadyWeaponEffect = new class'X2Effect_SteadyWeapon';
	SteadyWeaponEffect.EffectName = 'SteadyWeapon';
	SteadyWeaponEffect.BuildPersistentEffect(2 /* Turns */,,,,eGameRule_PlayerTurnEnd);  // eGameRule_UseActionPoint, eGameRule_PlayerTurnEnd, eGameRule_PlayerTurnBegin
	SteadyWeaponEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage);
	SteadyWeaponEffect.AddPersistentStatChange(eStat_Offense, default.STEADY_WEAPON_AIM_BONUS); // Give bonus aim
	SteadyWeaponEffect.DuplicateResponse = eDupe_Refresh;
	Template.AddTargetEffect(SteadyWeaponEffect);


	return Template;
}