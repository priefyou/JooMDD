/*
 * generated by Xtext
 */
package de.thm.icampus.joomdd.ejsl.generator

import de.thm.icampus.joomdd.ejsl.eJSL.CMSExtension
import de.thm.icampus.joomdd.ejsl.eJSL.EJSLModel
import de.thm.icampus.joomdd.ejsl.generator.ps.ExtensionGenerator
import de.thm.icampus.joomdd.ejsl.ressourceTransformator.RessourceTransformer
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import de.thm.icampus.joomdd.ejsl.generator.ps.EntityGenerator
import de.thm.icampus.joomdd.ejsl.generator.ps.PageGenerator

/**
 * Generates code from your model files on save.
 * 
 * see http://www.eclipse.org/Xtext/documentation.html#TutorialCodeGeneration
 */
class EJSLGenerator extends AbstractGenerator {
	
	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		
		
		for ( e : resource.allContents.toIterable.filter(typeof(EJSLModel))) {
			
			var EJSLModel domainModel = e as EJSLModel ;
			switch(domainModel.ejslPart){
				CMSExtension:
				{
					var CMSExtension extensionPart = domainModel.ejslPart as CMSExtension
					var RessourceTransformer trans = new RessourceTransformer(e)
			 		trans.dotransformation
					var ExtensionGenerator mainExtensionGen = new ExtensionGenerator(extensionPart.extensions,"Extensions/", fsa, domainModel.name)
					mainExtensionGen.dogenerate()
					var EntityGenerator mainEntitiesGen = new EntityGenerator(extensionPart.feature.entities, "Entities/", fsa, domainModel.name)
					mainEntitiesGen.dogenerate()
					var PageGenerator mainPageGen = new PageGenerator(extensionPart.feature.pages,fsa,"Pages/",domainModel.name)
				    mainPageGen.dogenerate()
				}
			}
			
		}
	}
}
