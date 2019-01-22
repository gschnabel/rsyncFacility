
#' Initialize Rsync
#'
#' Creates a list with functions that facilitate pushing and pulling files and directories from a remote machine.
#'
#' @param login ssh login in the form user@host
#' @param password ssh password
#' @param pwfile file whose first line contains ssh password (overrides \code{password})
#' @param socket socket file created by ssh for the communication (bypasses time dealy to login). optional.
#' @param tempdir.loc directory for temporary files
#' @param verbosity verbosity of status messages
#' @param timeout.con duration before an ongoing connection attempt is considered to be timed out
#' @param delay waiting times between connection attempts
#' @param delay2 upper limit of waiting times between connection attemps
#'
#' @details
#' The returned list contains the following functions:
#' \tabular{ll}{
#' \code{upSyncFile(srcFile, destFile)}\tab copy a file from the local to the remote machine\cr
#' \code{downSyncFile(srcFile, destFile)}\tab copy a file from the remote to the local machine\cr
#' \code{upMoveFile(srcFile, destFile)}\tab move a file from the local to the remote machine\cr
#' \code{downSyncFile(srcFile, destFile)}\tab move a file from the remote machine to the local machine\cr
#' \code{upSyncDir(srcDir, destDir)}\tab copy a directory recursively from the local to the remote machine\cr
#' \code{downSyncDir(srcDir, destDir)}\tab copy a directory recursively from the remote to the local machine\cr
#' \code{setSocketFile(newPath)}\tab change the path to the socket file (created by ssh)\cr
#' \code{getSocketFile()}\tab return the path to the socket file\cr
#' \code{closeCon()}\tab perform clean up operations when rsync is no longer needed
#' }
#'
#' @return
#' A list (think object) with functions to pull and push files and directories, see \code{details}
#' @export
initRsync <- function(login,password=NULL,pwfile=NULL,socket=NULL,
                      tempdir.loc, verbosity=1,
                      timeout.con=5,delay=c(5,10),
                      delay2=delay*1.5) {

  defaults <- list(timeout.con=timeout.con,delay=delay,
                   socket=socket, vebosity=verbosity)

  usedPwfile <- TRUE
  if (is.null(pwfile)) {
    pwfile <- system(paste0("mktemp -p '",tempdir.loc,"' -t login_XXXXXXXXX"),intern=TRUE)
    stopifnot(is.character(password))
    writeLines(password,pwfile)
    usedPwfile <- FALSE
  }
  stopifnot(file.exists(pwfile))


  loadDefaults <- function() {
    parfrm <- parent.frame()
    nm <- names(defaults)
    for (i in seq_along(nm))
      if (is.null(parfrm[[ nm[i] ]]))
        assign(nm[i],defaults[[i]],parfrm)
  }

  printInfo <- function(msg,verb) {
    loadDefaults()
    if (verb<=verbosity)
      cat(paste0(msg,"\n"))
  }

  setSocketFile <- function(newPath) {
    socket <<- newPath
    defaults[["socket"]] <<- newPath
  }

  getSocketFile <- function(newPath) {
    loadDefaults()
    socket
  }


  createRsyncCmd <- function(src,dest,timeout.con,other.args=character(0)) {
    loadDefaults()
    stopifnot(is.numeric(timeout.con),all(!grepl("'",src,fixed=TRUE)),!grepl("'",dest,fixed=TRUE))
    cmdstr <- paste0("sshpass -f '",pwfile,"' rsync ",
                     if (!is.null(socket))
                       paste0("-e \"ssh -o 'ControlPath=",socket,"'\"")
                     else "",
                     " --timeout ",timeout.con)
    if (length(other.args)>0)
      cmdstr <- paste(cmdstr,paste(other.args,collapse=" "),sep=" ")
    for (i in seq_along(src))
      cmdstr <- paste(cmdstr,paste0("'",src[i],"'"),sep=" ")
    cmdstr <- paste(cmdstr,paste0("'",dest,"'"),sep=" ")
    return(cmdstr)
  }

  retryLoop <- function(cmdstr,delay) {
    numtries <- 1
    #cat(cmdstr,"\n") #debug
    printInfo("Rsync - starting transfer...",2)
    while ((status <- system(cmdstr,intern=FALSE))!=0 && numtries <= length(delay)) {
      Sys.sleep(runif(1,delay[numtries],delay2[numtries]))
      printInfo(paste0("Rsync - ...retry attempt number ",numtries),2)
      numtries <- numtries + 1
    }
    stopifnot(status==0)
  }

  upSyncDir <- function(srcDir, destDir,  timeout.con=NULL,delay=NULL, other.args=character(0)) {
    loadDefaults()
    cmdstr <- createRsyncCmd(srcDir,paste(login,destDir,sep=":"),timeout.con,other.args=c("-r",other.args))
    retryLoop(cmdstr,delay)
  }

  downSyncDir <- function(srcDir, destDir, other.args=character(0)) {
    loadDefaults()
    cmdstr <- createRsyncCmd(paste(login,srcDir,sep=":"),destDir,timeout.con,other.args=c("-r",other.args))
    retryLoop(cmdstr,delay)
  }

  upSyncFile <- function(srcFile, destFile) {
    loadDefaults()
    cmdstr <- createRsyncCmd(srcFile,paste(login,destFile,sep=":"),timeout.con)
    retryLoop(cmdstr,delay)
  }

  downSyncFile <- function(srcFile, destFile) {
    loadDefaults()
    cmdstr <- createRsyncCmd(paste(login,srcFile,sep=":"),destFile,timeout.con)
    retryLoop(cmdstr,delay)
  }

  upMoveFile <- function(srcFile, destFile) {
    loadDefaults()
    cmdstr <- createRsyncCmd(srcFile,paste(login,destFile,sep=":"),timeout.con,
                             other.args="--remove-source-files")
    retryLoop(cmdstr,delay)
  }

  downMoveFile <- function(srcFile, destFile) {
    loadDefaults()
    cmdstr <- createRsyncCmd(paste(login,srcFile,sep=":"),destFile,timeout.con,
                             other.args="--remove-source-files")
    retryLoop(cmdstr,delay)
  }

  closeCon <- function() {
    if (!usedPwfile)
      file.remove(pwfile) # remove an auto-created pwfile
  }

  list(upSyncDir=upSyncDir, downSyncDir=downSyncDir,
       upSyncFile=upSyncFile, downSyncFile=downSyncFile,
       upMoveFile=upMoveFile, downMoveFile=downMoveFile,
       closeCon=closeCon, setSocketFile=setSocketFile, getSocketFile=getSocketFile)
}
