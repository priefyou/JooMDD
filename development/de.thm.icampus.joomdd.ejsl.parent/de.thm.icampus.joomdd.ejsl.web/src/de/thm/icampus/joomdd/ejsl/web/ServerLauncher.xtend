/*
 * generated by iCampus (JooMDD team) 2.9.1
 */
package de.thm.icampus.joomdd.ejsl.web

import java.net.InetSocketAddress
import org.eclipse.jetty.annotations.AnnotationConfiguration
import org.eclipse.jetty.server.Server
import org.eclipse.jetty.util.log.Slf4jLog
import org.eclipse.jetty.webapp.MetaInfConfiguration
import org.eclipse.jetty.webapp.WebAppContext
import org.eclipse.jetty.webapp.WebInfConfiguration
import org.eclipse.jetty.webapp.WebXmlConfiguration
import org.eclipse.xtext.resource.IResourceServiceProvider

/**
 * This program starts an HTTP server for testing the web integration of your DSL.
 * Just execute it and point a web browser to http://localhost:8080/
 */
class ServerLauncher {
		var static resourcesProvider = IResourceServiceProvider.Registry.INSTANCE
	
	def static void main(String[] args) { 
		val server = new Server(new InetSocketAddress('localhost', 8080))
		server.handler = new WebAppContext => [
			resourceBase = 'WebRoot'
			welcomeFiles = #["index.html"]
			contextPath = "/"
			configurations = #[
				new AnnotationConfiguration,
				new WebXmlConfiguration,
				new WebInfConfiguration,
				new MetaInfConfiguration
			]
			setAttribute(WebInfConfiguration.CONTAINER_JAR_PATTERN, '.*/de\\.thm\\.icampus\\.joomdd\\.ejsl\\.web/.*,.*\\.jar')
		]
		val log = new Slf4jLog(ServerLauncher.name)
		println(args.toString)
		try {
			
			
		server.start
			log.info('Server started ' + server.getURI + '...')
			new Thread[
				log.info('Press enter to stop the server...')
				val key = System.in.read
				if (key !== -1) {
					server.stop
				} else {
					log.warn('Console input is not available. In order to stop the server, you need to cancel process manually.')
				}
			].start
			server.join
		} catch (Exception exception) {
			log.warn(exception.message)
			System.exit(1)
		}
	}
}
