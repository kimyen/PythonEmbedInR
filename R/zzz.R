
pathToPythonLibraries<-function(libname, pkgname) {
  # Note: 'pythonLibs' is defined in configure.win
  # removing the '/'
  arch <- substring(Sys.getenv("R_ARCH"), 2)
  pathToPythonLibraries<-file.path(libname, pkgname, "pythonLibs", arch)
  pathToPythonLibraries<-gsub("/", "\\", pathToPythonLibraries, fixed=T)
  pathToPythonLibraries
}

# NOTE:  This is one of several places the version is hard coded.  See also AutodetectPython.R, configure, configure.win 
PYTHON_VERSION<-"3.5"

.onLoad <- function(libname, pkgname) {
  print(libname)
  if (Sys.info()['sysname']=="Windows"){
    # add python libraries to Path
    extendedPath <- sprintf("%s%s%s", Sys.getenv("PATH"), .Platform$path.sep, pathToPythonLibraries(libname, pkgname))
    Sys.setenv(PATH=extendedPath)
    packageRootDir<-file.path(libname, pkgname)
    Sys.setenv(PYTHONHOME=packageRootDir)

    arch <- substring(Sys.getenv("R_ARCH"), 2)
    pythonPathEnv<-paste(file.path(packageRootDir, "pythonLibs", arch), file.path(packageRootDir, "pythonLibs", arch, "Lib\\site-packages"), sep=";")
  } else {
    packageRootDir<-file.path(libname, pkgname)
    Sys.setenv(PYTHONHOME=packageRootDir)

    pythonPathEnv<-file.path(packageRootDir, "lib")
  }

  Sys.setenv(PYTHONPATH=pythonPathEnv)

  library.dynam.unload("PythonEmbedInR", packageRootDir)
  library.dynam("PythonEmbedInR", pkgname, libname, local=FALSE, verbose = TRUE)

  if (Sys.info()['sysname']=='Darwin') {
    sharedObjectFile<-system.file("lib/libcrypto.1.0.0.dylib", package="PythonEmbedInR")
    dyn.load(sharedObjectFile, local=FALSE)
    sharedObjectFile<-system.file("lib/libssl.1.0.0.dylib", package="PythonEmbedInR")
    dyn.load(sharedObjectFile, local=FALSE)
    Sys.setenv(SSL_CERT_FILE=system.file(paste0("lib/python", PYTHON_VERSION, "/site-packages/pip/_vendor/requests/cacert.pem"), package="PythonEmbedInR"))
  }
  if (Sys.info()['sysname']=="Linux") {
    # if we build a static library, libpythonX.Xm.a, instead of a dynamically linked one,
    # libpythonX.Xm.so.1.0, then don't do the following
    sharedObjectFile<-system.file(paste0("lib/libpython", PYTHON_VERSION, "m.so.1.0", package="PythonEmbedInR"))
    if (file.exists(sharedObjectFile)) {
      dyn.load(sharedObjectFile, local=FALSE)
    }
  }

  pyConnect()
  invisible(NULL)
}

.onUnload <- function( libpath ){
  pyExit()
  library.dynam.unload( "PythonEmbedInR", libpath )
}

