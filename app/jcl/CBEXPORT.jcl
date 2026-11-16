//CBEXPORT JOB 'Export Customer Data for Migration',CLASS=A,MSGCLASS=0,
// NOTIFY=&SYSUID
//******************************************************************
//* Copyright Amazon.com, Inc. or its affiliates.                   
//* All Rights Reserved.                                            
//*                                                                 
//* Licensed under the Apache License, Version 2.0 (the "License"). 
//* You may not use this file except in compliance with the License.
//* You may obtain a copy of the License at                         
//*                                                                 
//*    http://www.apache.org/licenses/LICENSE-2.0                   
//*                                                                 
//* Unless required by applicable law or agreed to in writing,      
//* software distributed under the License is distributed on an     
//* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,    
//* either express or implied. See the License for the specific     
//* language governing permissions and limitations under the License
//* *******************************************************************
//* EXPORT CUSTOMER DATA FROM VSAM FILES TO MULTI-RECORD EXPORT FILE
//* FOR BRANCH MIGRATION OR DATA TRANSFER PURPOSES
//* *******************************************************************
//* STEP 1: DELETE EXISTING EXPORT FILE IF PRESENT
//* *******************************************************************
//STEP01   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE AWS.M2.CARDDEMO.EXPORT.DATA PURGE
  SET MAXCC = 0
/*
//* *******************************************************************
//* STEP 2: RUN EXPORT PROGRAM
//* *******************************************************************
//STEP02 EXEC PGM=CBEXPORT
//STEPLIB  DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.LOADLIB
//*
//* INPUT VSAM FILES
//*
//CUSTFILE DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CUSTDATA.VSAM.KSDS
//ACCTFILE DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.ACCTDATA.VSAM.KSDS
//XREFFILE DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CARDXREF.VSAM.KSDS
//TRANSACT DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.TRANSACT.VSAM.KSDS
//CARDFILE DD DISP=SHR,
//         DSN=AWS.M2.CARDDEMO.CARDDATA.VSAM.KSDS
//*
//* OUTPUT EXPORT FILE
//*
//EXPFILE  DD DISP=(NEW,CATLG,DELETE),
//         DSN=AWS.M2.CARDDEMO.EXPORT.DATA,
//         UNIT=SYSDA,
//         SPACE=(CYL,(10,5),RLSE),
//         DCB=(RECFM=FB,LRECL=500,BLKSIZE=0)
//*
//* SYSTEM OUTPUT
//*
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//*
//*
//* Ver: CardDemo_v2.0-44-gb6e9c27-254 Date: 2025-10-16 14:07:18 CDT
//*
