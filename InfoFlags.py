#search for your flags at https://www-calipso.larc.nasa.gov/resources/calipso_users_guide/data_summaries/vfm/
import numpy as np
from InfoVert import *

#how many pixels to skip (it while take year otherwise to process all 60k pixels per orbit)
debugOffset=10

VFMflagDef="RAF_dust"
VFMflagDef="RAF_ALLbc"
VFMflagDef="RAF_smoke"
VFMflagDef="AerFrac"
VFMflagDef="CC"
VFMflagDef="CI2CT"


if VFMflagDef=="CI2CT":
	#Cloud_Ice_to_total_Cloud"
	VFMflagStart=6 #get flags 6-7 
	VFMflagFinish=7
	flagValues=[np.nan,1,0,1] #average them as: missing,1,0,1

if VFMflagDef=="CC" or VFMflagDef=="AerFrac":
	#CC
	VFMflagStart=1 
	VFMflagFinish=3
	flagValues=[
	np.nan,  	#0 = invalid (bad or missing data)
	0.,              #1 = "clear air"
	0.,              #2 = cloud
	0.,              #3 = tropospheric aerosol
	0.,              #4 = stratospheric aerosol
	np.nan,              #5 = surface
	np.nan,              #6 = subsurface
	np.nan]              #7 = no signal (totally attenuated
	if VFMflagDef=="CC": 
		flagValues[2]=1.0
	if VFMflagDef=="AerFrac":
		flagValues[3]=1.0
		flagValues[4]=1.0

###set the next flag to True only if you need to filter retrievals for cloud only or aerosol only (e.g., RAF calculation)
CondFlag=False
CondFlagStart =-1
CondFlagFinish=-1
CondFlagValue=-1 #3 = tropospheric aerosol
if "RAF" in VFMflagDef:
	CondFlag=True
	CondFlagStart =1
	CondFlagFinish=3
	CondFlagValue=3 #3 = tropospheric aerosol

if "RAF" in VFMflagDef:
	#AerosolType_to_totalSky"
	VFMflagStart=10
	VFMflagFinish=12
	flagValues=[
	np.nan,  	 #0 = not determined      
	0.,              #1 = clean marine        
	0.,              #2 = dust                
	0.,              #3 = polluted continental/smoke
	0.,              #4 = clean continental   
	0.,          #5 = polluted dust       
	0.,          #6 = elevated smoke               
	0.]          #7 = other               
if VFMflagDef=="RAF_smoke":
	flagValues[3]=1.0
	flagValues[6]=1.0
if VFMflagDef=="RAF_dust":
	flagValues[2]=1.0
if VFMflagDef=="RAF_ALLbc":
	flagValues[3]=1.0
	flagValues[5]=1.0
	flagValues[6]=1.0


















