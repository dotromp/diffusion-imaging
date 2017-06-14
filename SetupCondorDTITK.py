#!/usr/bin/env python
Version = "2.1"
#Utilizing elements created by Gary Hui Zhang (garyhuizhang@gmail.com), see credits below.
#Adapted for use in HTCondor and DAG by Andrew Schoen (schoen.andrewj@gmail.com)

#============================================================================
#
#  Program:     DTI ToolKit (DTI-TK)
#  Module:      $RCSfile: dti_rigid_sn,v $
#  Language:    bash
#  Date:        $Date: 2012/03/02 16:10:40 $
#  Version:     $Revision: 1.2 $
#
#  Copyright (c) Gary Hui Zhang (garyhuizhang@gmail.com).
#  All rights reserverd.
#
#  DTI-TK is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  DTI-TK is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with DTI-TK.  If not, see <http://www.gnu.org/licenses/>.
#============================================================================

doc = """
DTITK Condor Setup.
Usage:
  SetupCondorDTITK.py [options] <subject_file> <dtitk_root> <script_output_dir> <normalize_output_dir>
  SetupCondorDTITK.py [options] <subject_file> <dtitk_root> <script_output_dir> <normalize_output_dir> (-m | --monitor) <monitor_dir>
Arguments:
  <subject_file>          A csv file with the first column containing unique scan identifiers, and the second column containing the full path to their SPD input file. Headers are ID and PATH, respectively.
  <dtitk_root>            The location for your version of DTITK_ROOT
  <script_output_dir>     The output directory for the scripts
  <normalize_output_dir>  The output directory for your normalization. This should be a separate location from where your scans are located.
  <monitor_dir>           The directory to put the monitoring web page. This is required only if you specify the "-m --monitor" option.
Options:
  -h --help               Show this screen.
  -v --version            Show the current version.
  -k --keep               Keep all intermediate files [default: False]
  -m --monitor            Create a web page that monitors the progress of your processing.
  --regtype=<reg>         Registration type [default: NMI]
  --species=<species>     Species (either HUMAN, MONKEY, or RAT) [default: HUMAN]
  --rigid=<rigidcount>    Number of rigid iterations [default: 3]
  --affine=<affinecount>  Number of affine iterations [default: 3]
  --diffeo=<diffeocount>  Number of diffeomorphic iterations [default: 6]
  """

#============================================================================
#============ Importing things ==============================================

import os, sys, glob, shutil, csv, random, subprocess, math
from docopt import docopt

#============================================================================
#============ Argument Parsing and Cleanup ==================================

def cleanArguments(arguments):
    cleanArg={}
    cleanArg["SubjectFile"] = arguments["<subject_file>"]
    cleanArg["DTITK_ROOT"] = arguments["<dtitk_root>"]
    if cleanArg["DTITK_ROOT"].endswith("/"):
      argString = cleanArg["DTITK_ROOT"]
      cleanArg["DTITK_ROOT"] = argString[:-1]
    cleanArg["ScriptsDir"] = arguments["<script_output_dir>"]
    if cleanArg["ScriptsDir"].endswith("/"):
      argString = cleanArg["ScriptsDir"]
      cleanArg["ScriptsDir"] = argString[:-1]
    cleanArg["NormDir"] = arguments["<normalize_output_dir>"]
    if cleanArg["NormDir"].endswith("/"):
      argString = cleanArg["NormDir"]
      cleanArg["NormDir"] = argString[:-1]
    cleanArg["ShouldMonitor"] = arguments["--monitor"]
    cleanArg["ShouldKeep"] = arguments["--keep"]
    cleanArg["regType"] = arguments["--regtype"].upper()
    cleanArg["species"] = arguments["--species"].upper()
    cleanArg["RigidIterationMax"] = int(arguments["--rigid"])
    cleanArg["AffineIterationMax"] = int(arguments["--affine"])
    cleanArg["DiffeomorphicIterationMax"] = int(arguments["--diffeo"])
    cleanArg["scriptHeader"] = "#!/bin/bash\n#Utilizing elements created by Gary Hui Zhang (garyhuizhang@gmail.com), see credits in main script.\n#Adapted for use in HTCondor and DAG by Andrew Schoen (schoen.andrewj@gmail.com)\n#\n. {0}/scripts/dtitk_common.sh\nexport DTITK_ROOT={0}".format(arguments["<dtitk_root>"])
    if cleanArg["ShouldMonitor"] == True:
      cleanArg["MonitorDir"] = arguments["<monitor_dir>"]
      if cleanArg["MonitorDir"].endswith("/"):
        argString = cleanArg["MonitorDir"]
        cleanArg["MonitorDir"] = argString[:-1]
    else:
      cleanArg["MonitorDir"] = False
    if cleanArg["species"] == "MONKEY":
        cleanArg["sep_coarse"] = 2
        cleanArg["sep_fine"] = 1
    elif cleanArg["species"] == "RAT":
        cleanArg["sep_coarse"] = 0.4
        cleanArg["sep_fine"] = 0.2
    elif cleanArg["species"] == "HUMAN":
        cleanArg["sep_coarse"] = 4
        cleanArg["sep_fine"] = 2
    else:
        print("WARNING: The species input '{0}' did not match one of the existing options. Defaulting to 'HUMAN' settings.".format(cleanArg["species"]))
        cleanArg["sep_coarse"] = 4
        cleanArg["sep_fine"] = 2
    
    return cleanArg

def printInputs(argumentsDict):
    print("Inputs:")
    for key,value in argumentsDict.items():
        print("{0} = {1}".format(key, value))


#============================================================================
#============File Writing Utility============================================

#Let's Create some functions to write to our files

def writeRowToFile(text, filename):
    file = open(filename, 'a')
    file.write("{0}\n".format(text))
    file.close

def writeContinuedRowToFile(text, filename):
    file = open(filename, 'a')
    file.write("{0}".format(text))
    file.close
    
#============================================================================
#============System Calling Utility==========================================

#Create a shorthand for running system processes, such as FSL commands

def systemCall(command):
    p = subprocess.Popen([command], stdout=subprocess.PIPE, shell=True)
    return p.stdout.read()

#============================================================================
#============Script and Normalization Directories============================

def createDir(Dir):
  if os.path.exists(Dir):
      print("Directory '{0}' already exists".format(Dir))
  else:
      print("Directory '{0}' does not exist. Creating now.".format(Dir))
      os.mkdir(Dir)

#============================================================================
#============Clean up from Previous Runs=====================================

def cleanUpNormFromPrev(NormDir):
  #Remove anything currently in the normalization directory, so we can start fresh.
  print "Removing anything currently in the normalization directory, so we can start fresh."
  filelist = glob.glob("{0}/*".format(NormDir))
  for file in filelist:
      os.remove(file)

def cleanUpScriptsFromPrev(ScriptsDir):
  #Remove any previous scripts currently in the scripts directory, so we can start fresh.
  print "Removing any previous scripts currently in the scripts directory, so we can start fresh."
  filelist = glob.glob("{0}/*.sh".format(ScriptsDir))
  for file in filelist:
      os.remove(file)

#============================================================================
#============Condor Sub-Directory Creation===================================

def createSubDir(DirRoot, type):
  #Create a place to put the condor submit files and logs.
  print("Creating a place to put the {0}.".format(type))

  if os.path.exists("{0}/{1}".format(DirRoot, type)):
      if os.path.exists("{0}/{1}_archived".format(DirRoot, type)):
          shutil.rmtree("{0}/{1}_archived".format(DirRoot, type))
      os.rename("{0}/{1}".format(DirRoot, type), "{0}/{1}_archived".format(DirRoot, type))
    
  os.mkdir("{0}/{1}".format(DirRoot, type))

#============================================================================
#============Subject File Parsing============================================

def parseCSV(csvfilepath):
    if os.path.exists(csvfilepath):
      print("Parsing CSV File '{0}'.".format(csvfilepath))
      with open(csvfilepath) as csvfile:
        firstline = csvfile.readline()
        if firstline != "ID,PATH\n":
          print("CSV File does not contain the correct header. It should be two-column CSV with headers of ID and PATH")
          sys.exit(1)
        csvfile.seek(0)
        reader = csv.DictReader(csvfile)
        scans=[]
        for scan in reader:
            scans.append(scan)
        
        return scans
    else:
        print("CSV File '{0}' does not exist! Exiting now.".format(csvfilepath))
        sys.exit(1)

#============================================================================
#============Define Additional Dimension Variables===========================

def addDimVars(scans, arguments):
    randomScan = random.choice(scans)
    randomScanID = randomScan["ID"]
    randomScanPath = randomScan["PATH"]
    print("Randomly selected scan {0} ({1}) to define dimensions for bootstrapping.".format(randomScanID, randomScanPath))
    if glob.glob("/apps/fsl*"):
        print("Using FSL to determine the dimensions of your output file.")
        xdim = float(systemCall('fslval {0} dim1'.format(randomScanPath)))
        ydim = float(systemCall('fslval {0} dim2'.format(randomScanPath)))
        zdim = float(systemCall('fslval {0} dim3'.format(randomScanPath)))
        xpixdim = float(systemCall('fslval {0} pixdim1'.format(randomScanPath)))
        ypixdim = float(systemCall('fslval {0} pixdim2'.format(randomScanPath)))
        zpixdim = float(systemCall('fslval {0} pixdim3'.format(randomScanPath)))
        
        #Add the calculated values to arguments
        arguments["xsize"] = math.ceil(xdim * xpixdim / 64)
        arguments["ysize"] = math.ceil(ydim * ypixdim / 64)
        arguments["zsize"] = math.ceil(zdim * zpixdim / 64)
    else:
        print("You do not have FSL installed. Please enter in the voxel dimensions of your output file manually")
        arguments["xsize"] = float(input("Voxel Size in the X dimension: "))
        arguments["ysize"] = float(input("Voxel Size in the Y dimension: "))
        arguments["zsize"] = float(input("Voxel Size in the Z dimension: "))
    return arguments

#============================================================================
#============Subject List Creation===========================================

def createScanLists(scans, NormDir):
  #Add subject to lists for processing
  print "Creating scan list files."

  for scan in scans:
      id=scan["ID"]
      writeRowToFile("{0}_spd.nii.gz".format(id), "{0}/scan_list_file.txt".format(NormDir))
      print("Scan {0} added to scan_list_file.txt".format(id))
    
      writeRowToFile("{0}_spd_aff.nii.gz".format(id), "{0}/scan_list_file_aff.txt".format(NormDir))
      print("Scan {0} added to scan_list_file_aff.txt".format(id))
    
      writeRowToFile("{0}_spd_aff_diffeo.nii.gz".format(id), "{0}/scan_list_file_aff_diffeo.txt".format(NormDir))
      print("Scan {0} added to scan_list_file_aff_diffeo.txt".format(id))
    
      writeRowToFile("{0}_spd.aff".format(id), "{0}/affine.txt".format(NormDir))
      print("Scan {0} added to affine.txt".format(id))
    
      writeRowToFile("{0}_spd_aff_diffeo.df.nii.gz".format(id), "{0}/diffeo.txt".format(NormDir))
      print("Scan {0} added to diffeo.txt".format(id))

  print "Scan list files created."

def linkScans(scans, NormDir):
  #Link to the subject's relevant files from the normalization directory you specified
  for scan in scans:
      id=scan["ID"]
      path=scan["PATH"]
      print("Linking Scan {0} files in the Normalization Directory".format(id))
      os.symlink(path, "{0}/{1}_spd.nii.gz".format(NormDir, id))
      print("Scan {0} files linked in the Normalization Directory".format(id))

def createJobObjForMonitor(scans):
  jobs = []
  jobs.append({"ID":"Group", "NAME":"Group"})
  for scan in scans:
    jobs.append({"ID":scan["ID"], "NAME":scan["ID"]})
  return jobs

#============================================================================
#============Script List Creation============================================

def createIndividualScriptsList(RigidIterationMax, AffineIterationMax, DiffeomorphicIterationMax):
    #Create a list of individual processes
    print "Creating a list of the different individual scripts to be run."

    #Create an empty array.
    individualScriptList = list()

    #Rigid Step (variable numbers)
    RigidUpperBound = RigidIterationMax + 1
    for iteration in range(1,RigidUpperBound):
        individualScriptList.append("Individual_Rigid{0}".format(iteration))

    #Affine Step (variable numbers)
    AffineUpperBound = AffineIterationMax + 1
    for iteration in range(1,AffineUpperBound):
        individualScriptList.append("Individual_Affine{0}A".format(iteration))
        individualScriptList.append("Individual_Affine{0}B".format(iteration))

    #Diffeomorphic Step (variable numbers)
    DiffeomorphicUpperBound = DiffeomorphicIterationMax + 1
    for iteration in range(1,DiffeomorphicUpperBound):
       individualScriptList.append("Individual_Diffeomorphic{0}".format(iteration))
    
    return individualScriptList
  
def createGroupScriptsList(RigidIterationMax, AffineIterationMax, DiffeomorphicIterationMax):
  #Create a list of group processes
  print "Creating a list of the different group scripts to be run."
  
  #Create an empty array.
  groupScriptList = list()

  #Bootstrapping (only one round)
  groupScriptList.append("Group_Bootstrap")

  #Rigid Step (variable numbers)
  RigidUpperBound = RigidIterationMax + 1
  for iteration in range(1,RigidUpperBound):
      groupScriptList.append("Group_Rigid{0}".format(iteration))

  #Affine Step (variable numbers)
  AffineUpperBound = AffineIterationMax + 1
  for iteration in range(1,AffineUpperBound):
      groupScriptList.append("Group_Affine{0}A".format(iteration))
      groupScriptList.append("Group_Affine{0}B".format(iteration))

  #Diffeomorphic Step (variable numbers)
  DiffeomorphicUpperBound = DiffeomorphicIterationMax + 1
  for iteration in range(1,DiffeomorphicUpperBound):
      groupScriptList.append("Group_Diffeomorphic{0}".format(iteration))
  
  return groupScriptList

def createEventObjForMonitor(RigidIterationMax, AffineIterationMax, DiffeomorphicIterationMax):
  events = []
  
  events.append({"ID":"B", "NAME":"Bootstrap"})
  
  RigidUpperBound = RigidIterationMax + 1
  for iteration in range(1,RigidUpperBound):
    events.append({"ID":"R{0}".format(iteration), "NAME":"Rigid {0}".format(iteration)})
  
  AffineUpperBound = AffineIterationMax + 1
  for iteration in range(1,AffineUpperBound):
    events.append({"ID":"A{0}A".format(iteration), "NAME":"Affine {0}A".format(iteration)})
    events.append({"ID":"A{0}B".format(iteration), "NAME":"Affine {0}B".format(iteration)})
    
  DiffeomorphicUpperBound = DiffeomorphicIterationMax + 1
  for iteration in range(1,DiffeomorphicUpperBound):
    events.append({"ID":"D{0}".format(iteration), "NAME":"Diffeo {0}".format(iteration)})
  
  return events

#============================================================================
#============Condor Submit File Creation - Individual Processes==============

def createSubmitIndiv(ScriptsDir, NormDir, individualScriptList, scans):
  #Create the condor_submit files for individual processes.
  for scan in scans:
      print("Individual Submit files for {0}".format(scan["ID"]))
      for script in individualScriptList:
          print("Current Process: {0}".format(script))
          currentSubmit="{0}/condorsubmit/cs_{1}_{2}.condor".format(ScriptsDir, scan["ID"], script)
          writeRowToFile("Universe=vanilla", currentSubmit)
          writeRowToFile("initialdir={0}".format(NormDir), currentSubmit)
          writeRowToFile("getenv=True", currentSubmit)
          writeRowToFile("request_memory=1024", currentSubmit)
          writeRowToFile("Executable={0}/{1}.sh".format(ScriptsDir, script), currentSubmit)
          writeRowToFile("Log={0}/condorlogs/{1}_{2}_log.txt".format(ScriptsDir, scan["ID"], script), currentSubmit)
          writeRowToFile("Output={0}/condorlogs/{1}_{2}_out.txt".format(ScriptsDir, scan["ID"], script), currentSubmit)
          writeRowToFile("Error={0}/condorlogs/{1}_{2}_err.txt".format(ScriptsDir, scan["ID"], script), currentSubmit)
          writeRowToFile("Notification=NEVER", currentSubmit)
          writeRowToFile("Arguments={0}".format(scan["ID"]), currentSubmit)
          writeRowToFile("Queue", currentSubmit)

#============================================================================
#============Condor Submit File Creation - Group Processes===================

def createSubmitGrp(ScriptsDir, NormDir, groupScriptList):
  #Create the condor_submit files for group processes.
  print("Group Submit files for all subjects")
  for script in groupScriptList:
      print("Current Process: {0}".format(script))
      currentSubmit="{0}/condorsubmit/cs_{1}.condor".format(ScriptsDir, script)
      writeRowToFile("Universe=vanilla", currentSubmit)
      writeRowToFile("initialdir={0}".format(NormDir), currentSubmit)
      writeRowToFile("getenv=True", currentSubmit)
      writeRowToFile("request_memory=1024", currentSubmit)
      writeRowToFile("Executable={0}/{1}.sh".format(ScriptsDir, script), currentSubmit)
      writeRowToFile("Log={0}/condorlogs/{1}_log.txt".format(ScriptsDir, script), currentSubmit)
      writeRowToFile("Output={0}/condorlogs/{1}_out.txt".format(ScriptsDir, script), currentSubmit)
      writeRowToFile("Error={0}/condorlogs/{1}_err.txt".format(ScriptsDir, script), currentSubmit)
      writeRowToFile("Notification=NEVER", currentSubmit)
      writeRowToFile("Queue", currentSubmit)

#============================================================================
#============DAGMan File Creation============================================

def createDAG(ScriptsDir, groupScriptList, individualScriptList, scans):
  #Create the DAGMan file for putting it all together.
  print("Creating the DAG File.")
  dagFile="{0}/condorsubmit/DAG_DTITK.dag".format(ScriptsDir)

  writeRowToFile("#File name: DAG_DTITK.dag", dagFile)
  writeRowToFile("#", dagFile)

  #Declaring Jobs

  #Group Components
  print("Group Components")
  writeRowToFile("#Group Components", dagFile)
  for script in groupScriptList:
      writeRowToFile("JOB {0} {1}/condorsubmit/cs_{0}.condor".format(script, ScriptsDir), dagFile)
    
  #Individual Components
  print("Individual Components")
  writeRowToFile("#Individual Components", dagFile)
  for script in individualScriptList:
      print("Current script = {0}".format(script))
      for scan in scans:
          writeRowToFile("JOB {0}_{1} {2}/condorsubmit/cs_{0}_{1}.condor".format(scan["ID"], script, ScriptsDir), dagFile)

  #Dependencies
  print("Dependencies")
  writeRowToFile("#Dependencies", dagFile)
  stepUpperBound = len(individualScriptList)
  for step in range(0,stepUpperBound):
      CurrentParent = groupScriptList[step]
      CurrentTask = individualScriptList[step]
      CurrentChild = groupScriptList[step + 1]
    
      writeContinuedRowToFile("PARENT {0} CHILD".format(CurrentParent), dagFile)
      for scan in scans:
          writeContinuedRowToFile(" ", dagFile)
          writeContinuedRowToFile("{0}_{1}".format(scan["ID"], CurrentTask), dagFile)
      writeRowToFile(" ", dagFile)

      writeContinuedRowToFile("PARENT", dagFile)
      for scan in scans:
          writeContinuedRowToFile(" ", dagFile)
          writeContinuedRowToFile("{0}_{1}".format(scan["ID"], CurrentTask), dagFile)
      writeRowToFile(" CHILD {0}".format(CurrentChild), dagFile)

  print("DTITK DAG Setup -> COMPLETE")



#============================================================================
#============Script Creation - Group Processes===============================

#Header for Script Generation
#scriptHeader = "#!/bin/bash\n#Utilizing elements created by Gary Hui Zhang (garyhuizhang@gmail.com), see credits in main script.\n#Adapted for use in HTCondor and DAG by Andrew Schoen (schoen.andrewj@gmail.com)\n#\n. {0}/scripts/dtitk_common.sh\nexport DTITK_ROOT={0}".format(DTITK_ROOT)

#Script generation for Step 1: Bootstrapping
def writeStep1(ScriptsDir, scriptHeader, xsize, ysize, zsize, ShouldMonitor, MonitorDir):
    currentScript="{0}/Group_Bootstrap.sh".format(ScriptsDir)
    writeRowToFile(scriptHeader, currentScript)
    writeRowToFile("echo 'DTI Step 1: Bootstrapping for all scans'", currentScript)
    if ShouldMonitor == True:
      writeRowToFile("{0}/statusupdate.py Group B Running".format(MonitorDir), currentScript)
      #Step 1
      writeRowToFile("errcount=0", currentScript)
      writeRowToFile("if TVMean -in scan_list_file.txt -out dti_mean_initial.nii.gz ; then", currentScript)
      writeRowToFile("  errcount=expr $errcount+0", currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  echo 'There was an error with TVMean'", currentScript)
      writeRowToFile("  errcount=expr $errcount+1", currentScript)
      writeRowToFile("fi", currentScript)
      #Step 2
      writeRowToFile("if TVResample -in dti_mean_initial.nii.gz -vsize {0} {1} {2} -size 128 128 64 ; then".format(xsize, ysize, zsize), currentScript)
      writeRowToFile("  errcount=expr $errcount+0", currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  echo 'There was an error with TVResample'", currentScript)
      writeRowToFile("  errcount=expr $errcount+1", currentScript)
      writeRowToFile("fi", currentScript)
      #Error check and Update
      writeRowToFile("if [[ $errcount == 0 ]] ; then", currentScript)
      writeRowToFile("  {0}/statusupdate.py Group B Finished".format(MonitorDir), currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  {0}/statusupdate.py Group B Error".format(MonitorDir), currentScript)
      writeRowToFile("fi", currentScript)
    else:
      writeRowToFile("TVMean -in scan_list_file.txt -out dti_mean_initial.nii.gz", currentScript)
      writeRowToFile("TVResample -in dti_mean_initial.nii.gz -vsize {0} {1} {2} -size 128 128 64".format(xsize, ysize, zsize), currentScript)
    writeRowToFile("cp dti_mean_initial.nii.gz mean_rigid0.nii.gz", currentScript)
    writeRowToFile("echo 'DTI Step 1: Bootstrapping for all scans -> COMPLETE!'", currentScript)

#Script generation for Step 2: Rigid Normalization (Individual Steps)
def writeStep2Iter(iter, iterMax, ScriptsDir, scriptHeader, DTITK_ROOT, regType, sep_coarse, ShouldMonitor, MonitorDir):
    prevIter= iter - 1
    currentScript="{0}/Individual_Rigid{1}.sh".format(ScriptsDir, iter)
    writeRowToFile(scriptHeader, currentScript)
    writeRowToFile("scan=$1", currentScript)
    writeRowToFile('echo "Current Scan: ${scan}"', currentScript)
    writeRowToFile("echo 'DTI Step 2.{0}: Rigid Alignment, Iteration {0}'".format(iter), currentScript)
    if ShouldMonitor == True:
      writeRowToFile("{0}/statusupdate.py ${{scan}} R{1} Running".format(MonitorDir, iter), currentScript)
      if iter == 1:
        writeRowToFile("if {0}/scripts/dti_rigid_reg mean_rigid{1}.nii.gz ${{scan}}_spd.nii.gz {2} {3} {3} {3} 0.01 ; then".format(DTITK_ROOT, prevIter, regType, sep_coarse), currentScript)
      else:
        writeRowToFile("if {0}/scripts/dti_rigid_reg mean_rigid{1}.nii.gz ${{scan}}_spd.nii.gz {2} {3} {3} {3} 0.01 1 ; then".format(DTITK_ROOT, prevIter, regType, sep_coarse), currentScript)
      writeRowToFile("  {0}/statusupdate.py ${{scan}} R{1} Finished".format(MonitorDir, iter), currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  {0}/statusupdate.py ${{scan}} R{1} Error".format(MonitorDir, iter), currentScript)
      writeRowToFile("fi", currentScript)
    else:
      if iter == 1:
        writeRowToFile("{0}/scripts/dti_rigid_reg mean_rigid{1}.nii.gz ${{scan}}_spd.nii.gz {2} {3} {3} {3} 0.01".format(DTITK_ROOT, prevIter, regType, sep_coarse), currentScript)
      else:
        writeRowToFile("{0}/scripts/dti_rigid_reg mean_rigid{1}.nii.gz ${{scan}}_spd.nii.gz {2} {3} {3} {3} 0.01 1".format(DTITK_ROOT, prevIter, regType, sep_coarse), currentScript)
    writeRowToFile("echo 'DTI Step 2.{0}: Rigid Alignment, Iteration {0} -> COMPLETE!'".format(iter), currentScript)

#Script generation for Step 3a: Affine Normalization (Individual Steps)
def writeStep3IterA(iter, iterMax, ScriptsDir, scriptHeader, DTITK_ROOT, regType, sep_coarse, ShouldMonitor, MonitorDir):
    prevIter= iter - 1
    currentScript="{0}/Individual_Affine{1}A.sh".format(ScriptsDir, iter)
    writeRowToFile(scriptHeader, currentScript)
    writeRowToFile("scan=$1", currentScript)
    writeRowToFile('echo "Current Scan: ${scan}"', currentScript)
    writeRowToFile("echo 'DTI Step 3.{0}a: Affine Alignment, Iteration {0}, Part A'".format(iter), currentScript)
    if ShouldMonitor == True:
      writeRowToFile("{0}/statusupdate.py ${{scan}} A{1}A Running".format(MonitorDir, iter), currentScript)
      writeRowToFile("if {0}/scripts/dti_affine_reg mean_affine{1}.nii.gz ${{scan}}_spd.nii.gz {2} {3} {3} {3} 0.01 1 ; then".format(DTITK_ROOT, prevIter, regType, sep_coarse), currentScript)
      writeRowToFile("  {0}/statusupdate.py ${{scan}} A{1}A Finished".format(MonitorDir, iter), currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  {0}/statusupdate.py ${{scan}} A{1}A Error".format(MonitorDir, iter), currentScript)
      writeRowToFile("fi", currentScript)
    else:
      writeRowToFile("{0}/scripts/dti_affine_reg mean_affine{1}.nii.gz ${{scan}}_spd.nii.gz {2} {3} {3} {3} 0.01 1".format(DTITK_ROOT, prevIter, regType, sep_coarse), currentScript)
    writeRowToFile("echo 'DTI Step 3.{0}a: Affine Alignment, Iteration {0}, Part A -> COMPLETE!'".format(iter), currentScript)

#Script generation for Step 3b: Affine Normalization (Individual Steps)
def writeStep3IterB(iter, iterMax, ScriptsDir, scriptHeader, ShouldMonitor, MonitorDir):
    prevIter= iter - 1
    currentScript="{0}/Individual_Affine{1}B.sh".format(ScriptsDir, iter)
    writeRowToFile(scriptHeader, currentScript)
    writeRowToFile("scan=$1", currentScript)
    writeRowToFile('echo "Current Scan: ${scan}"', currentScript)
    writeRowToFile("echo 'DTI Step 3.{0}b: Affine Alignment, Iteration {0}, Part B'".format(iter), currentScript)
    if ShouldMonitor == True:
      writeRowToFile("{0}/statusupdate.py ${{scan}} A{1}B Running".format(MonitorDir, iter), currentScript)
      #Step 1
      writeRowToFile("errcount=0", currentScript)
      writeRowToFile("if affine3Dtool -in ${scan}_spd.aff -compose average_inv.aff -out ${scan}_spd.aff ; then", currentScript)
      writeRowToFile("  errcount=expr $errcount+0".format(MonitorDir, iter), currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  echo 'There was an error with affine3Dtool'", currentScript)
      writeRowToFile("  errcount=expr $errcount+1".format(MonitorDir, iter), currentScript)
      writeRowToFile("fi", currentScript)
      #Step 2
      writeRowToFile("if affineSymTensor3DVolume -in ${{scan}}_spd.nii.gz -trans ${{scan}}_spd.aff -target mean_affine{0}.nii.gz -out ${{scan}}_spd_aff.nii.gz ; then".format(prevIter), currentScript)
      writeRowToFile("  errcount=expr $errcount+0".format(MonitorDir, iter), currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  echo 'There was an error with affineSymTensor3DVolume'", currentScript)
      writeRowToFile("  errcount=expr $errcount+1".format(MonitorDir, iter), currentScript)
      writeRowToFile("fi", currentScript)
      #Error check and Update
      writeRowToFile("if [[ $errcount == 0 ]] ; then", currentScript)
      writeRowToFile("  {0}/statusupdate.py ${{scan}} A{1}B Finished".format(MonitorDir, iter), currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  {0}/statusupdate.py ${{scan}} A{1}B Error".format(MonitorDir, iter), currentScript)
      writeRowToFile("fi", currentScript)
    else:
      writeRowToFile("affine3Dtool -in ${scan}_spd.aff -compose average_inv.aff -out ${scan}_spd.aff", currentScript)
      writeRowToFile("affineSymTensor3DVolume -in ${{scan}}_spd.nii.gz -trans ${{scan}}_spd.aff -target mean_affine{0}.nii.gz -out ${{scan}}_spd_aff.nii.gz".format(prevIter), currentScript)
    writeRowToFile("echo 'DTI Step 3.{0}b: Affine Alignment, Iteration {0}, Part B -> COMPLETE!'".format(iter), currentScript)

#Script generation for Step 4: Diffeomorphic Normalization (Individual Steps)
def writeStep4Iter(iter, iterMax, ScriptsDir, scriptHeader, DTITK_ROOT, ShouldMonitor, MonitorDir):
    prevIter= iter - 1
    currentScript="{0}/Individual_Diffeomorphic{1}.sh".format(ScriptsDir, iter)
    writeRowToFile(scriptHeader, currentScript)
    writeRowToFile("scan=$1", currentScript)
    writeRowToFile('echo "Current Scan: ${scan}"', currentScript)
    writeRowToFile("echo 'DTI Step 4.{0}: Diffeomorphic Alignment, Iteration {0}'".format(iter), currentScript)
    if ShouldMonitor == True:
      writeRowToFile("{0}/statusupdate.py ${{scan}} D{1} Running".format(MonitorDir, iter), currentScript)
      writeRowToFile("if {0}/scripts/dti_diffeomorphic_reg mean_diffeomorphic_initial.nii.gz ${{scan}}_spd_aff.nii.gz mask.nii.gz 1 {1} 0.002 ; then".format(DTITK_ROOT, iter), currentScript)
      writeRowToFile("  {0}/statusupdate.py ${{scan}} D{1} Finished".format(MonitorDir, iter), currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  {0}/statusupdate.py ${{scan}} D{1} Error".format(MonitorDir, iter), currentScript)
      writeRowToFile("fi", currentScript)
    else:
      writeRowToFile("{0}/scripts/dti_diffeomorphic_reg mean_diffeomorphic_initial.nii.gz ${{scan}}_spd_aff.nii.gz mask.nii.gz 1 {1} 0.002".format(DTITK_ROOT, iter), currentScript)
    writeRowToFile("echo 'DTI Step 4.{0}: Diffeomorphic Alignment, Iteration {0} -> COMPLETE!'".format(iter), currentScript)

#Script generation for Step 2: Rigid Normalization (Group Steps)
def writeStep2Inter(inter, interMax, ScriptsDir, scriptHeader, regType, ShouldMonitor, MonitorDir):
    prevInter= inter - 1
    currentScript="{0}/Group_Rigid{1}.sh".format(ScriptsDir, inter)
    writeRowToFile(scriptHeader, currentScript)
    writeRowToFile('echo "DTI Step 2.{0}.1: Adjusting Rigid Average for all scans, Iteration {0}"'.format(inter), currentScript)
    if ShouldMonitor == True:
      writeRowToFile("{0}/statusupdate.py Group R{1} Running".format(MonitorDir, inter), currentScript)
      #Step 1
      writeRowToFile("errcount=0", currentScript)
      writeRowToFile("if TVMean -in scan_list_file_aff.txt -out mean_rigid{0}.nii.gz ; then".format(inter), currentScript)
      writeRowToFile("  errcount=expr $errcount+0", currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  echo 'There was an error with TVMean'", currentScript)
      writeRowToFile("  errcount=expr $errcount+1", currentScript)
      writeRowToFile("fi", currentScript)
      #Step 2
      writeRowToFile("if TVtool -in mean_rigid{0}.nii.gz -sm mean_rigid{1}.nii.gz -SMOption  {2} | grep Similarity | tee -a rigid_normalization.log ; then".format(prevInter, inter, regType), currentScript)
      writeRowToFile("  errcount=expr $errcount+0", currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  echo 'There was an error with TVtool'", currentScript)
      writeRowToFile("  errcount=expr $errcount+1", currentScript)
      writeRowToFile("fi", currentScript)
      #Error check and Update
      writeRowToFile("if [[ $errcount == 0 ]] ; then", currentScript)
      writeRowToFile("  {0}/statusupdate.py Group R{1} Finished".format(MonitorDir, inter), currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  {0}/statusupdate.py Group R{1} Error".format(MonitorDir, inter), currentScript)
      writeRowToFile("fi", currentScript)
    else:
      writeRowToFile("TVMean -in scan_list_file_aff.txt -out mean_rigid{0}.nii.gz".format(inter), currentScript)
      writeRowToFile("TVtool -in mean_rigid{0}.nii.gz -sm mean_rigid{1}.nii.gz -SMOption  {2} | grep Similarity | tee -a rigid_normalization.log".format(prevInter, inter, regType), currentScript)
    writeRowToFile('echo "DTI Step 2.{0}.1: Adjusting Rigid Average for all scans, Iteration {0} -> COMPLETE!"'.format(inter), currentScript)
    if inter == interMax:
        writeRowToFile("#Prepare for the affine alignment in the next step by copying over the file we just created.", currentScript)
        writeRowToFile("cp mean_rigid{0}.nii.gz mean_affine0.nii.gz".format(inter), currentScript)

#Script generation for Step 3a: Affine Normalization (Group Steps)
def writeStep3InterA(inter, interMax, ScriptsDir, scriptHeader, ShouldMonitor, MonitorDir):
    prevInter= inter - 1
    currentScript="{0}/Group_Affine{1}A.sh".format(ScriptsDir, inter)
    writeRowToFile(scriptHeader, currentScript)
    writeRowToFile('echo "DTI Step 3.{0}a.1: Adjusting Affine Average for all scans, Iteration {0}"'.format(inter), currentScript)
    if ShouldMonitor == True:
      writeRowToFile("{0}/statusupdate.py Group A{1}A Running".format(MonitorDir, inter), currentScript)
      writeRowToFile("if affine3DShapeAverage affine.txt mean_affine{0}.nii.gz average_inv.aff 1 ; then".format(prevInter), currentScript)
      writeRowToFile("  {0}/statusupdate.py Group A{1}A Finished".format(MonitorDir, inter), currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  {0}/statusupdate.py Group A{1}A Error".format(MonitorDir, inter), currentScript)
      writeRowToFile("fi", currentScript)
    else:
      writeRowToFile("affine3DShapeAverage affine.txt mean_affine{0}.nii.gz average_inv.aff 1".format(prevInter), currentScript)
    writeRowToFile('echo "DTI Step 3.{0}a.1: Adjusting Affine Average for all scans, Iteration {0} -> COMPLETE!"'.format(inter), currentScript)

#Script generation for Step 3b: Affine Normalization (Group Steps)
def writeStep3InterB(inter, interMax, ScriptsDir, scriptHeader, regType, ShouldMonitor, MonitorDir):
    prevInter= inter - 1
    currentScript="{0}/Group_Affine{1}B.sh".format(ScriptsDir, inter)
    writeRowToFile(scriptHeader, currentScript)
    writeRowToFile('echo "DTI Step 3.{0}b.1: Adjusting Affine Average for all scans, Iteration {0}"'.format(inter), currentScript)
    
    if ShouldMonitor == True:
      writeRowToFile("{0}/statusupdate.py Group A{1}B Running".format(MonitorDir, inter), currentScript)
      writeRowToFile("errcount=0", currentScript)
    writeRowToFile("rm -fr average_inv.aff", currentScript) 
    if ShouldMonitor == True:
      #Step 1
      writeRowToFile("if TVMean -in scan_list_file_aff.txt -out mean_affine{0}.nii.gz ; then".format(inter), currentScript)
      writeRowToFile("  errcount=expr $errcount+0", currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  echo 'There was an error with TVMean'", currentScript)
      writeRowToFile("  errcount=expr $errcount+1", currentScript)
      writeRowToFile("fi", currentScript)
      #Step 2
      writeRowToFile("if TVtool -in mean_affine{0}.nii.gz -sm mean_affine{1}.nii.gz -SMOption  {2} | grep Similarity | tee -a affine_normalization.log ; then".format(prevInter, inter, regType), currentScript)
      writeRowToFile("  errcount=expr $errcount+0", currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  echo 'There was an error with TVtool'", currentScript)
      writeRowToFile("  errcount=expr $errcount+1", currentScript)
      writeRowToFile("fi", currentScript)
    else:
      writeRowToFile("TVMean -in scan_list_file_aff.txt -out mean_affine{0}.nii.gz".format(inter), currentScript)
      writeRowToFile("TVtool -in mean_affine{0}.nii.gz -sm mean_affine{1}.nii.gz -SMOption  {2} | grep Similarity | tee -a affine_normalization.log".format(prevInter, inter, regType), currentScript)
    
    writeRowToFile('echo "DTI Step 3.{0}b.1: Adjusting Affine Average for all scans, Iteration {0} -> COMPLETE!"'.format(inter), currentScript)
    if inter == interMax:
        writeRowToFile("echo 'Preparing for Diffeomorphic Alignment'", currentScript) 
        if ShouldMonitor == True:
          #Step 3
          writeRowToFile("if TVtool -tr -in mean_affine{0}.nii.gz ; then".format(inter), currentScript)
          writeRowToFile("  errcount=expr $errcount+0", currentScript)
          writeRowToFile("else", currentScript)
          writeRowToFile("  echo 'There was an error with TVtool'", currentScript)
          writeRowToFile("  errcount=expr $errcount+1", currentScript)
          writeRowToFile("fi", currentScript)
          #Step 4
          writeRowToFile("if BinaryThresholdImageFilter mean_affine{0}_tr.nii.gz mask.nii.gz 0 .01 100 1 0 ; then".format(inter), currentScript)
          writeRowToFile("  errcount=expr $errcount+0", currentScript)
          writeRowToFile("else", currentScript)
          writeRowToFile("  echo 'There was an error with BinaryThresholdFilter'", currentScript)
          writeRowToFile("  errcount=expr $errcount+1", currentScript)
          writeRowToFile("fi", currentScript)
        else:
          writeRowToFile("TVtool -tr -in mean_affine{0}.nii.gz".format(inter), currentScript)
          writeRowToFile("BinaryThresholdImageFilter mean_affine{0}_tr.nii.gz mask.nii.gz 0 .01 100 1 0".format(inter), currentScript)
        writeRowToFile("#Prepare for the diffeomorphic alignment in the next step by copying over the file we just created.", currentScript)
        writeRowToFile("cp mean_affine{0}.nii.gz mean_diffeomorphic0.nii.gz".format(inter), currentScript)
        writeRowToFile("ln -sf mean_diffeomorphic0.nii.gz mean_diffeomorphic_initial.nii.gz", currentScript)
    if ShouldMonitor == True:
      writeRowToFile("if [[ $errcount == 0 ]] ; then", currentScript)
      writeRowToFile("  {0}/statusupdate.py Group A{1}B Finished".format(MonitorDir, inter), currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  {0}/statusupdate.py Group A{1}B Error".format(MonitorDir, inter), currentScript)
      writeRowToFile("fi", currentScript)

#Script generation for Step 4: Diffeomorphic Normalization (Group Steps)
def writeStep4Inter(inter, interMax, ScriptsDir, scriptHeader, ShouldMonitor, MonitorDir, ShouldKeep):
    prevInter= inter - 1
    currentScript="{0}/Group_Diffeomorphic{1}.sh".format(ScriptsDir, inter)
    writeRowToFile(scriptHeader, currentScript)
    writeRowToFile("echo 'DTI Step 4.{0}.1: Adjusting Diffeomorphic Average for all scans, Iteration {0}'".format(inter), currentScript)
    
    if ShouldMonitor == True:
      writeRowToFile("{0}/statusupdate.py Group D{1} Running".format(MonitorDir, inter), currentScript)
      writeRowToFile("errcount=0", currentScript)
      #Step 1
      writeRowToFile("if TVMean -in scan_list_file_aff_diffeo.txt -out mean_diffeomorphic{0}.nii.gz ; then".format(inter), currentScript)
      writeRowToFile("  errcount=expr $errcount+0", currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  echo 'There was an error with TVMean'", currentScript)
      writeRowToFile("  errcount=expr $errcount+1", currentScript)
      writeRowToFile("fi", currentScript)
      #Step 2
      writeRowToFile("if VVMean -in diffeo.txt -out mean_df.nii.gz ; then", currentScript)
      writeRowToFile("  errcount=expr $errcount+0", currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  echo 'There was an error with VVMean'", currentScript)
      writeRowToFile("  errcount=expr $errcount+1", currentScript)
      writeRowToFile("fi", currentScript)
      #Step 3
      writeRowToFile("if dfToInverse -in mean_df.nii.gz ; then", currentScript)
      writeRowToFile("  errcount=expr $errcount+0", currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  echo 'There was an error with dfToInverse'", currentScript)
      writeRowToFile("  errcount=expr $errcount+1", currentScript)
      writeRowToFile("fi", currentScript)
      #Step 4
      writeRowToFile("if deformationSymTensor3DVolume -in mean_diffeomorphic{0}.nii.gz -out mean_diffeomorphic{0}.nii.gz -trans mean_df_inv.nii.gz ; then".format(inter), currentScript)
      writeRowToFile("  errcount=expr $errcount+0", currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  echo 'There was an error with deformationSymTensor3DVolume'", currentScript)
      writeRowToFile("  errcount=expr $errcount+1", currentScript)
      writeRowToFile("fi", currentScript)
    else:
      writeRowToFile("TVMean -in scan_list_file_aff_diffeo.txt -out mean_diffeomorphic{0}.nii.gz".format(inter), currentScript)
      writeRowToFile("VVMean -in diffeo.txt -out mean_df.nii.gz", currentScript)
      writeRowToFile("dfToInverse -in mean_df.nii.gz", currentScript)
      writeRowToFile("deformationSymTensor3DVolume -in mean_diffeomorphic{0}.nii.gz -out mean_diffeomorphic{0}.nii.gz -trans mean_df_inv.nii.gz".format(inter), currentScript)
    writeRowToFile("#Clear up the temporary files", currentScript)
    writeRowToFile("rm -fr mean_diffeomorphic_initial.nii.gz", currentScript)
    if inter != interMax:
        writeRowToFile("#Make the new working file.", currentScript)
        writeRowToFile("ln -sf mean_diffeomorphic{0}.nii.gz mean_diffeomorphic_initial.nii.gz".format(inter), currentScript)
    writeRowToFile("echo 'DTI Step 4.{0}.1: Adjusting Diffeomorphic Average for all scans, Iteration {0} -> COMPLETE!'".format(inter), currentScript)
    if inter == interMax:
        writeRowToFile("mkdir output", currentScript)
        writeRowToFile("cp mean_diffeomorphic{0}.nii.gz output/mean.nii.gz".format(inter), currentScript)
        writeRowToFile("cp *_diffeo.nii.gz output/", currentScript)
        writeRowToFile("cp *.df.nii.gz output/", currentScript)
        writeRowToFile("cp *.aff output/", currentScript)
        if ShouldKeep == False:
           #Remove all files that aren't in "output"
           writeRowToFile("rm -f *.*", currentScript)
           writeRowToFile("mv output/* ./", currentScript)
           writeRowToFile("rm -rf output", currentScript)
        writeRowToFile("echo '#'", currentScript)
        writeRowToFile("echo 'ALL DONE'", currentScript)
    if ShouldMonitor == True:
      writeRowToFile("if [[ $errcount == 0 ]] ; then", currentScript)
      writeRowToFile("  {0}/statusupdate.py Group D{1} Finished".format(MonitorDir, inter), currentScript)
      writeRowToFile("else", currentScript)
      writeRowToFile("  {0}/statusupdate.py Group D{1} Error".format(MonitorDir, inter), currentScript)
      writeRowToFile("fi", currentScript)

#============================================================================
#============ Main ==========================================================

def setup(arguments):   
    print
    #Directory Creation and Cleanup
    print("## Directory Creation and Cleanup ##")
    createDir(arguments["NormDir"])
    createDir(arguments["ScriptsDir"])
    cleanUpNormFromPrev(arguments["NormDir"])
    cleanUpScriptsFromPrev(arguments["ScriptsDir"])
    createSubDir(arguments["ScriptsDir"], "condorlogs")
    createSubDir(arguments["ScriptsDir"], "condorsubmit")
    print
    
    #CSV File Parsing
    print("## CSV File Parsing ##")
    scans = parseCSV(arguments["SubjectFile"])
    print
    
    #Defining Additional Dimension Variables
    print("## Defining Additional Dimension Variables ##")
    arguments = addDimVars(scans, arguments)
    print(arguments)
    
    #Scan List Creation
    print("## Scan List Creation ##")
    createScanLists(scans, arguments["NormDir"])
    print
    
    #Scan Link Creation
    print("## Scan Link Creation ##")
    linkScans(scans, arguments["NormDir"])
    print
    
    #Script List Creation
    print("## Script List Creation ##")
    individualScriptList = createIndividualScriptsList(arguments["RigidIterationMax"], arguments["AffineIterationMax"], arguments["DiffeomorphicIterationMax"])
    groupScriptList = createGroupScriptsList(arguments["RigidIterationMax"], arguments["AffineIterationMax"], arguments["DiffeomorphicIterationMax"])
    print
    
    #Condor Submit File Creation
    print("## Condor Submit File Creation ##")
    createSubmitIndiv(arguments["ScriptsDir"], arguments["NormDir"], individualScriptList, scans)
    createSubmitGrp(arguments["ScriptsDir"], arguments["NormDir"], groupScriptList)
    print
    
    #DAG File Creation
    print("## DAG File Creation ##")
    createDAG(arguments["ScriptsDir"], groupScriptList, individualScriptList, scans)
    print
    
    #Job Monitoring
    if arguments["ShouldMonitor"] == True:
      import SetupJobMonitor
      #Make Jobs Object
      jobsObj = createJobObjForMonitor(scans)
      #Make Events Object
      eventsObj = createEventObjForMonitor(arguments["RigidIterationMax"], arguments["AffineIterationMax"], arguments["DiffeomorphicIterationMax"])
      #Assemble JobMonitor Arguments
      argsForMonitor = {"processName":"DTITK | Live Updates", "monitorDir":arguments["MonitorDir"], "jobs":jobsObj, "events":eventsObj}
      
      #Run SetupJobMonitor.py
      SetupJobMonitor.create(argsForMonitor)
      
    #Script Creation
    print("## Script Creation ##")
    print "Script generation for Step 1:  Bootstrapping"
    writeStep1(arguments["ScriptsDir"], arguments["scriptHeader"], arguments["xsize"], arguments["ysize"], arguments["zsize"], arguments["ShouldMonitor"], arguments["MonitorDir"])
    
    print "Script generation for Step 2:  Rigid Normalization (Individual Steps)"
    for iter in range(1, arguments["RigidIterationMax"] + 1):
      writeStep2Iter(iter, arguments["RigidIterationMax"], arguments["ScriptsDir"], arguments["scriptHeader"], arguments["DTITK_ROOT"], arguments["regType"], arguments["sep_coarse"], arguments["ShouldMonitor"], arguments["MonitorDir"])
    
    print "Script generation for Step 2:  Rigid Normalization (Group Steps)"
    for inter in range(1, arguments["RigidIterationMax"] + 1):
      writeStep2Inter(inter, arguments["RigidIterationMax"], arguments["ScriptsDir"], arguments["scriptHeader"], arguments["regType"], arguments["ShouldMonitor"], arguments["MonitorDir"])
    
    print "Script generation for Step 3a: Affine Normalization (Individual Steps)"
    for iter in range(1, arguments["AffineIterationMax"] + 1):
      writeStep3IterA(iter, arguments["AffineIterationMax"], arguments["ScriptsDir"], arguments["scriptHeader"], arguments["DTITK_ROOT"], arguments["regType"], arguments["sep_coarse"], arguments["ShouldMonitor"], arguments["MonitorDir"])
    
    print "Script generation for Step 3a: Affine Normalization (Group Steps)"
    for inter in range(1, arguments["AffineIterationMax"] + 1):
      writeStep3InterA(inter, arguments["AffineIterationMax"], arguments["ScriptsDir"], arguments["scriptHeader"], arguments["ShouldMonitor"], arguments["MonitorDir"])
    
    print "Script generation for Step 3b: Affine Normalization (Individual Steps)"
    for iter in range(1, arguments["AffineIterationMax"] + 1):
      writeStep3IterB(iter, arguments["AffineIterationMax"], arguments["ScriptsDir"], arguments["scriptHeader"], arguments["ShouldMonitor"], arguments["MonitorDir"])
    
    print "Script generation for Step 3b: Affine Normalization (Group Steps)"
    for inter in range(1, arguments["AffineIterationMax"] + 1):
      writeStep3InterB(inter, arguments["AffineIterationMax"], arguments["ScriptsDir"], arguments["scriptHeader"], arguments["regType"], arguments["ShouldMonitor"], arguments["MonitorDir"])
    
    print "Script generation for Step 4:  Diffeomorphic Normalization (Individual Steps)"
    for iter in range(1, arguments["DiffeomorphicIterationMax"] + 1):
      writeStep4Iter(iter, arguments["DiffeomorphicIterationMax"], arguments["ScriptsDir"], arguments["scriptHeader"], arguments["DTITK_ROOT"], arguments["ShouldMonitor"], arguments["MonitorDir"])
    
    print "Script generation for Step 4:  Diffeomorphic Normalization (Group Steps)"
    for inter in range(1, arguments["DiffeomorphicIterationMax"] + 1):
      writeStep4Inter(inter, arguments["DiffeomorphicIterationMax"], arguments["ScriptsDir"], arguments["scriptHeader"], arguments["ShouldMonitor"], arguments["MonitorDir"], arguments["ShouldKeep"])
    
    #Make those scripts executable.
    for script in glob.glob("{0}/*.sh".format(arguments["ScriptsDir"])):
      os.chmod(script, os.stat(script).st_mode | 0111) 
    print
    print("Setup Complete")

#============================================================================
#============ DocOpt ========================================================

def go(args):
    #Argument Parsing
    arguments = docopt(doc, argv=args, version='DTITK Condor Setup {0}'.format(Version))
    print("## Argument Parsing ##")
    arguments = cleanArguments(arguments)
    printInputs(arguments)
    print
    setup(arguments)

#============================================================================
#============ Main ==========================================================

if __name__ == '__main__':
    args = sys.argv
    del args[0]    
    go(args)
else:
    print("Encountered an error in your input")

