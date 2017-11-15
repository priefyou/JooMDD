/*
 * generated by iCampus (JooMDD team) 2.9.1
 */
package de.thm.icampus.joomdd.ejsl.web

import com.google.inject.Provider
import java.util.List
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import javax.servlet.annotation.WebServlet
import org.eclipse.xtext.resource.IResourceServiceProvider
import org.eclipse.xtext.web.servlet.XtextServlet

/** 
 * Deploy this class into a servlet container to enable DSL-specific services.
 */
@WebServlet(name = 'XtextServices', urlPatterns = '/xtext-service/*')
class EJSLServlet extends XtextServlet {
	 
	val List<ExecutorService> executorServices = newArrayList
	
	var resourcesProvider = IResourceServiceProvider.Registry.INSTANCE
	
	override init() {
		if(resourcesProvider != null){
			new SessionProvider(this.servletContext);
		}				
		super.init()
		val Provider<ExecutorService> executorServiceProvider = [Executors.newCachedThreadPool => [executorServices += it]]
		new EJSLWebSetup(executorServiceProvider).createInjectorAndDoEMFRegistration()
	}
	
	override destroy() {
		println("destroy server or session")
		executorServices.forEach[shutdown()]
		executorServices.clear()
		super.destroy()
	}
}
