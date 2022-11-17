================================
README
================================
Step to operate the compiled application:

1) Prerequisites for Deployment 
Verify that version 9.5 (R2018b) of the MATLAB Runtime is installed. (default installation folder is /usr/local/MATLAB/MATLAB_Runtime/v95/ but it can be customized)
If not:
	- Download and install the Linux version of the MATLAB Runtime for R2018b (9.5 64 bits) from the following link on the MathWorks website: https://www.mathworks.com/products/compiler/matlab-runtime.html
	- (installation command on linux : ./install at the root of the MATLAB Runtime archive)

2) Define configuration file 
Refer to the decoder user manual to know what the variables correspond to.

Notes :
- GEBCO_2021.nc (for TEST004_GEBCO_FILE variable) can be downloaded here https://www.bodc.ac.uk/data/open_download/gebco/gebco_2021/zip/
- gl_greylist.txt (for TEST015_GREY_LIST_FILE variable) file available in the decGlider_misc folder of this archive.
- EGO_format_1.4.json file (for EGO_FORMAT_JSON_FILE variable) is available in the decGlider_soft/soft/json/ folder of this archive.
- XML_DIRECTORY variable is not used in this compiled version.



3) Run gl_process_glider application

Available files:
- gl_process_glider 
- run_gl_process_glider.sh (shell script for temporarily setting environment variables and 
                           executing the application)
- _glider_decoder_conf.txt (configuration file)				   
- This readme file 


To run the shell script, type
./run_gl_process_glider.sh <mcr_directory> <argument_list>

at Linux or Mac command prompt. <mcr_directory> is the directory 
where version 9.5 of the MATLAB Runtime is installed or the directory where 
MATLAB is installed on the machine. <argument_list> is all the 
arguments you want to pass to your application. For example, 

Exemple:
./run_gl_process_glider.sh /usr/local/MATLAB/MATLAB_Runtime/v95/ glidertype seaexplorer data kraken_eurec_tmp



================================
Appendices
================================
A1 Definitions

For information on deployment terminology, go to
http://www.mathworks.com/help and select MATLAB Compiler >
Getting Started > About Application Deployment >
Deployment Product Terms in the MathWorks Documentation
Center.

A2. Appendix 

A. Linux systems:
In the following directions, replace MR/v95 by the directory on the target machine where 
   MATLAB is installed, or MR by the directory where the MATLAB Runtime is installed.

(1) Set the environment variable XAPPLRESDIR to this value:

MR/v95/X11/app-defaults


(2) If the environment variable LD_LIBRARY_PATH is undefined, set it to the following:

MR/v95/runtime/glnxa64:MR/v95/bin/glnxa64:MR/v95/sys/os/glnxa64:MR/v95/sys/opengl/lib/glnxa64

If it is defined, set it to the following:

${LD_LIBRARY_PATH}:MR/v95/runtime/glnxa64:MR/v95/bin/glnxa64:MR/v95/sys/os/glnxa64:MR/v95/sys/opengl/lib/glnxa64

    For more detailed information about setting the MATLAB Runtime paths, see Package and 
   Distribute in the MATLAB Compiler documentation in the MathWorks Documentation Center.

        NOTE: To make these changes persistent after logout on Linux 
              or Mac machines, modify the .cshrc file to include this  
              setenv command.
        NOTE: The environment variable syntax utilizes forward 
              slashes (/), delimited by colons (:).  
        NOTE: When deploying standalone applications, you can
              run the shell script file run_gl_process_glider.sh 
              instead of setting environment variables. See 
              section 2 "Files to Deploy and Package".    






