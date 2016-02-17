class XComGameState_Effect_SteadyWeapon extends XComGameState_BaseObject config(GameData_SteadyWeapon);

function XComGameState_Effect_SteadyWeapon InitComponent()
{
	return self;
}

function XComGameState_Effect GetOwningEffect()
{
	return XComGameState_Effect(`XCOMHISTORY.GetGameStateForObjectID(OwningObjectId));
}

simulated function EventListenerReturn SteadyWeapon_ObjectMoved(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_EffectRemoved RemoveContext;
	local XComGameState NewGameState;
	local XComGameState_Effect EffectState;

	EffectState = GetOwningEffect();
	RemoveContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(EffectState);
	NewGameState = `XCOMHISTORY.CreateNewGameState(true, RemoveContext);
	EffectState.RemoveEffect(NewGameState, GameState);
	SubmitNewGameState(NewGameState);

	return ELR_NoInterrupt;
}

function EventListenerReturn SteadyWeapon_AbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_Ability AbilityState;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != None)
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
		if (AbilityTemplate != None)
		{
			if (AbilityTemplate.Hostility == eHostility_Offensive)
			{
				AbilityState = XComGameState_Ability(GameState.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
				if (AbilityState == None)
					AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

				if (AbilityState != None)
				{
					if (AbilityState.IsAbilityInputTriggered())
					{
						SteadyWeapon_ObjectMoved(EventData, EventSource, GameState, EventID);
					}
				}
			}
		}
	}
	return ELR_NoInterrupt;
}


private function SubmitNewGameState(out XComGameState NewGameState)
{
	local X2TacticalGameRuleset TacticalRules;
	local XComGameStateHistory History;

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		TacticalRules = `TACTICALRULES;
		TacticalRules.SubmitGameState(NewGameState);

		//  effects may have changed action availability - if a unit died, took damage, etc.
	}
	else
	{
		History = `XCOMHISTORY;
		History.CleanupPendingGameState(NewGameState);
	}
}
