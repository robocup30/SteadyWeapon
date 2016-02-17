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
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_aim"; // I can't draw, use overwatch icon for now
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_SHOT_PRIORITY; // Where ability gets placed on the tactical UI bar
	Template.bDisplayInUITooltip = false; // I have no idea what this does actually

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = SteadyWeaponAbility_BuildVisualization;

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


simulated function SteadyWeaponAbility_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference          InteractingUnitRef;
	local X2AbilityTemplate             AbilityTemplate;
	local XComGameState_Unit            UnitState;

	local VisualizationTrack        EmptyTrack;
	local VisualizationTrack        BuildTrack;

	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************	
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	UnitState = XComGameState_Unit(BuildTrack.StateObject_NewState);
	
	//Civilians on the neutral team are not allowed to have sound + flyover for hunker down
	if( UnitState.GetTeam() != eTeam_Neutral )
	{
		
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, Context));
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);
		SoundAndFlyOver.SetSoundAndFlyOverParameters(SoundCue'SoundUI.OverWatchCue', AbilityTemplate.LocFlyOverText, '', eColor_Good, AbilityTemplate.IconImage);
		OutVisualizationTracks.AddItem(BuildTrack);
	}
	//****************************************************************************************
}