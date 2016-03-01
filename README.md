# DCS Vagrant & Docker Images 

## Quickstart
* First, create some shared directories on your local filesystem.  [Edit `DockerHostVagrantfile`](#editing-dockerhostvagrantfile) if you wish to stray from the defaults:
	* A directory for packages (default `/shared/package-ingest`).  
		* Subdirectories of this can be used for package deposit or failed packages.  
		* When the package ingest service starts, it will create subdirectories `packages` and `fail-packages`.  Placing packages into `packages` will ingest into the Fedora root container.
	* A directory for Fedora/Jetty logs (default `/shared/jetty`)
		* A subdirectory `log` will be created and filled with jetty logs from the running Fedora instance.
	* A directory for karaf deployment/configuration and logs (default `/shared/karaf`)
		* Karaf will automatically create the `log` subdirectory for logging the package ingest service.
		* Create a subdirectory named `deploy` if you want to deploy files (like config files) to Karaf
* Next, in the project directory (the one containing `Vagrantfile`), run `vagrant up`
	* If you failed to create one of the above directories, Vagrant will yell at you and refuse to start.
	* You'll see lots of text fly by as it launches a VM, builds a docker image, and starts.  This can take several minutes.

## Verification
* Point your browser to [http://localhost:8181/system/console/components](http://localhost:8181/system/console/components).
	* You should see an Apache Karaf page
	* You should see a list of org.dataconservancy components with status `active`
* point your browser to Fedora at [http://localhost:8080/fcrepo/rest](http://localhost:8080/fcrepo/rest)
	* You should see an empty root container
* Drop some packages into the deposit dir(s) and watch them ingest
			* The default deposit dir, which ingests into Fedora's root directory is `/shared/package-ingest/packages` (or simply the `packages` subdirectory if you specified a non-default package ingest folder).
	* The service is configured to wait 30 seconds before ingesting a package
		* You can change this by going into [OSGI-> components](http://localhost:8181/system/console/components) menu of the webconsole, clicking on the wrench icon by the by PackageFileDepositWorkflow service, and editing the value of the package poll interval, in milliseconds.  Default is 30000 (30 seconds).  Click 'save', and the changes will be in effect immediately
	* You may wish to set up e-mail notifications (see below)
* Once a package has been processed, it will disappear from the deposit directory.  If it has failed, it will appear in the package fail directory.  Otherwise, it's in Fedora!

## E-mail notification Configuration
By default, the service is configured to simply log deposits to the karaf log.  You may want to set it up to send e-mails once a deposit is finished.  You can do this in two ways:

### Via webconsole
This method of storing configuration is persistent within a single container instance.  The container can be started/stopped, but the configuration is persisted in that container's filesystem locally.  If the container is destroyed, a new container will not retain configuration created through the webconsole.  Also, any configuration via files (see below) will override the webconsole config if the container is re-started.

 - Navigate to [OSGi->Configuration](http://localhost:8181/system/console/configMgr)
 - Find `org.dataconservancy.packaging.ingest.camel.impl.EmailNotifications` and click on it to bring up a form.
 - Fill out all the requested values and click 'save'
 - Go to [OSGi->Components](http://localhost:8181/system/console/components) and click the stop button (black square) next to LoggerNotifications.


### Via configuration files
This method of storing configuration is persistent across containers - you can completely erase a container, create a new one, point it to the config, and it should work as configured.
* Create a `/shared/karaf/deploy` directory (This assumes you kept the default karaf dir of `/shared/karaf`.  If not, just create a `deploy` subdirectory of wherever the shared karaf directory happens to be).
	* Create a file in the deploy directory named `org.dataconservancy.packaging.ingest.camel.impl.EmailNotifications.cfg` with the following contents
		* mail.smtpHost = YOUR_SMTP_SERVER (e.g. smtp.gmail.com)
mail.smtpUser = YOUR_EMAIL
mail.smtpPass = YOUR_PASSWORD
mail.from = FROM_ADDRESS
mail.to = TO_ADDRESS
* Create a file in the deploy directory named `org.dataconservancy.packaging.ingest.camel.impl.LoggerNotifications.cfg` with the following contents
	* `service.ranking = -2`
		* This explicitly disables/de-prioritizes the default logging notification.  Ideally, this step wouldn't be necessary, but testing has revealed that the notification implementation won't be swapped out until this happens.


## Setting up new deposit locations
In order to deposit into a non-root container in Fedora (like adding collections to a project),  you need to add a package deposit workflow that monitors a directory and ingests packages into a given Fedora container.

### Via configuration files
This method of storing configuration is persistent across containers - you can completely erase a container, create a new one, point it to the config, and it should work as configured.

 - Create a `/shared/karaf/deploy` directory, if one doesn't exist already (This assumes you kept the default karaf dir of `/shared/karaf`.  If not, just create a `deploy` subdirectory of wherever the shared karaf directory happens to be).  This is where you will put the Karaf configuration
 - Create a new directory for packages to be deposited into the container.  It has to be somewhere underneath `/shared/package-ingest` (or wherever the package ingest directory is, if you strayed from the defaults).  Let's call this `/shared/package-ingest/myPackages` for the sake of argument
 - Optionally, create a directory for failed packages.  Only do this if you want to keep track of where failed packages came from.  Otherwise, it's fine to use the same failed package directory for every deposit workflow (e.g. `/shared/package-ingest/failed-packages`
 - Create a text file in the `deploy` directory named `org.dataconservancy.packaging.ingest.camel.impl.PackageFileDepositWorkflow-myPackages.cfg`.  
	 - The part after the dash, `-myPackages.cfg` has to be unique for each workflow, and should be an informative name, like `-ELOKAProject.cfg` or `-cowImagesCollection.cfg`.   
	 - Populate the config file with the following content
		 - `deposit.location = http://CONTAINER-URI
package.deposit.dir = /shared/package-ingest/PATH-TO-PACKAGE_DIR
package.fail.dir = /shared/package-ingest/failed-packages
package.poll.interval.ms = 1000
` where CONTAINER-URI is a URI of a Fedora container (e.g. from a notification e-mail), PATH-TO-PACKAGE-DIR is the relative path to an package deposit dir.  
			 - Important:  The deposit and fail dirs are filesystem paths _on the docker container_ and therefore always start with `/shared/package-ingest`, regardless of where the file is on your local machine.  So if you have your shared package-ingest directory at `c:\Users\Me\Vagrant\packageDepositShared\` and created a package deposit directory of `c:\Users\Me\Vagrant\packageDepositShared\collection1\toDeposit`, you would specify in the configuration file `package.deposit.dir = /shared/package-ingest/collection1/toDeposit`
				 - The `package.poll.interval.ms` is optional.  Default is 30 seconds (30000) if unspecified.

## Editing `DockerHostVagrantfile`
By default the following directories on your local filesystem are shared with the DCS Vagrant and Docker images
* `/shared/package-ingest`: Subdirectories of this directory are where you'll place packages for deposit and where failed packages will appear.
* `/shared/jetty`: This directory will contain the logs for the Fedora instance that your packages are deposited to.
* `/shared/karaf`: This directory will contain the logs for the Karaf instance that runs the Package Ingest Service.

_Shared_ means that the contents of these directories can be read from or written to by your local operating system _and_ the DCS Vagrant and Docker images.  As the virtual machines update content in these directories, you can see the updates (e.g. `tail -f /shared/karaf/log/karaf.log`).  Likewise the virtual machines can see the content you place in these shared directories (e.g. `cp my-package.tar.gz /shared/package-ingest/packages`).

If you want to use different paths other than those above, open `DockerHostVagrantfile` and edit the section:

<pre>
  # Local folders for packages and karaf config
  config.vm.synced_folder "/shared/package-ingest", "/shared/package-ingest",
     mount_options: ["dmode=777", "fmode=666"]
  config.vm.synced_folder "/shared/karaf", "/shared/karaf",
     mount_options: ["dmode=777", "fmode=666"]
  config.vm.synced_folder "/shared/jetty", "/shared/jetty",
     mount_options: ["dmode=777", "fmode=666"]
</pre>

The left and right parameters to `config.vm.synced_folder` govern where these directories reside on the local and remote (virtual machine) file systems respectively.  If you wanted to keep everything under a specific user's home directory, for example, you could replace the left parameters with `/home/esm/packageingestservice-runtime/package-dir`, `/home/esm/packageingestservice-runtime/karaf`, and `/home/esm/packageingestservice-runtime/jetty`:

<pre>
    # Local folders for packages and karaf config
  config.vm.synced_folder "/home/esm/packageingestservice-runtime/package-dir", "/shared/package-ingest",
     mount_options: ["dmode=777", "fmode=666"]
  config.vm.synced_folder "/home/esm/packageingestservice-runtime/karaf", "/shared/karaf",
     mount_options: ["dmode=777", "fmode=666"]
  config.vm.synced_folder "/home/esm/packageingestservice-runtime/jetty", "/shared/jetty",
     mount_options: ["dmode=777", "fmode=666"]
</pre>


*_You need to create these directories yourself_*

*_Do not change the right parameters_*

After verifying that the services are up and running (see below), you should be able to deposit a new package by copying it to `/home/esm/packageingestservice-runtime/package-dir/packages`, and see log files appear in `/home/esm/packageingestservice-runtime/jetty/logs` and `/home/esm/packageingestservice-runtime/karaf/log`.
