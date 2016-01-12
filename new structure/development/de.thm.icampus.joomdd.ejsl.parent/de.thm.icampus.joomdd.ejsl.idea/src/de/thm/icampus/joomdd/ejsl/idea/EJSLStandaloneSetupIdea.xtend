/*
 * generated by iCampus (JooMDD team) 2.9.1
 */
package de.thm.icampus.joomdd.ejsl.idea

import com.google.inject.Guice
import de.thm.icampus.joomdd.ejsl.EJSLRuntimeModule
import de.thm.icampus.joomdd.ejsl.EJSLStandaloneSetupGenerated
import org.eclipse.xtext.util.Modules2

class EJSLStandaloneSetupIdea extends EJSLStandaloneSetupGenerated {
	override createInjector() {
		val runtimeModule = new EJSLRuntimeModule()
		val ideaModule = new EJSLIdeaModule()
		val mergedModule = Modules2.mixin(runtimeModule, ideaModule)
		return Guice.createInjector(mergedModule)
	}
}