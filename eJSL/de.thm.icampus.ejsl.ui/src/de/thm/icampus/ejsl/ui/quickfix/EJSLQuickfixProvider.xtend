/*
 * generated by Xtext
 */
package de.thm.icampus.ejsl.ui.quickfix

import de.thm.icampus.ejsl.validation.EJSLValidator

import org.eclipse.xtext.ui.editor.quickfix.Fix
import org.eclipse.xtext.ui.editor.quickfix.IssueResolutionAcceptor
import org.eclipse.xtext.validation.Issue
import de.thm.icampus.ejsl.eJSL.Attribute
import de.thm.icampus.ejsl.eJSL.Reference
import de.thm.icampus.ejsl.eJSL.Manifestation
import de.thm.icampus.ejsl.eJSL.Author
import de.thm.icampus.ejsl.eJSL.Language
import de.thm.icampus.ejsl.eJSL.Component
import de.thm.icampus.ejsl.eJSL.Page
import de.thm.icampus.ejsl.eJSL.IndexPage
import de.thm.icampus.ejsl.eJSL.Entity
import java.util.HashSet
import org.eclipse.xtext.ui.editor.model.IXtextDocument

/**
 * Custom quickfixes.
 * 
 * see http://www.eclipse.org/Xtext/documentation.html#quickfixes
 */
class EJSLQuickfixProvider extends org.eclipse.xtext.ui.editor.quickfix.DefaultQuickfixProvider {

	@Fix(EJSLValidator::AMBIGUOUS_ENTITY)
	def addIDtoEntity(Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, 'Add ID to Entity', 'Change the name.', '') [ context |
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset + issue.length, 1, "_ID_"+ issue.lineNumber.toString +" " )
		]
	}

	@Fix(EJSLValidator::AMBIGUOUS_LANGUAGE)
	def deletedoubleLanguageKey(Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, 'Delete Language', 'Remove the LanguageKey.', '') [ language, context |
			val doubleLang = language as Language
			val c = doubleLang.eContainer as Component
			c.languages.remove(doubleLang)
		]
	}

	@Fix(EJSLValidator::AMBIGUOUS_DATATYPE)
	def addIDtoDatatype(Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, 'Add ID to Datatype', 'Change the name.', '') [ context |
			val xtextDocument = context.xtextDocument					
			xtextDocument.replace(issue.offset + issue.length - 1, 1, "_ID_"+ issue.lineNumber.toString +"\" ")
		]
		acceptor.accept(issue, 'Delete Datatype', 'Remove the Datatype.', '') [ context |
			val xtextDocument = context.xtextDocument
			System.out.print(acceptor.toString)
			val lineofffset = xtextDocument.getLineOffset(issue.lineNumber - 1)
			xtextDocument.replace(lineofffset, 20, "")
		]
	}

	@Fix(EJSLValidator::INVALID_AUTHOR_URL)
	def validURL(Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, 'Set "http" before', 'Setting HTTP:// before invalid URL', '') [ context |
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset, 1, "\"http://") // http:// bevor "-char
		]
		acceptor.accept(issue, 'Set "https" before', 'Setting HTTPS:// before invalid URL', '') [ context |
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset, 1, "\"https://") // https:// bevor "-char
		]
	}

	@Fix(EJSLValidator::MISSING_PRIMARY_ATTRIBUTE)
	def fixNonExistingPrimaryAttribute(Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, 'Add primary attribute', 'Adding primary attribute to the first Attribute', '')[ element, context |
			val allAttributes = element.eContents						// get all attributes from the entity 
			val firstAttribute = allAttributes.get(0) as Attribute		// select the first attribute and convert it to de.thm.icampus.ejsl.eJSL.Attribute
			firstAttribute.isprimary = true								// set the Primary attribute to true
		]
	}
	
	@Fix(EJSLValidator::NOT_PRIMARY_REFERENCE)
	def fixReferenceAttributeError(Issue issue, IssueResolutionAcceptor acceptor){
		acceptor.accept(issue, 'Change to a primary attribute.', 'Change the attribute to a primary attribute from the same entity.', '')[ reference, context |
			val ref = reference as Reference
			var hasNewReference = false
			val parentEntity = ref.getEntity				// first get the parent entity of the reference
			val allAttributes = parentEntity.eContents		// then get all attributes of this entity
			
			for(att : allAttributes){						// now look which of the attributes is a primary and set the first as attributereferenced
				val a = att as Attribute
				if(a.isIsprimary && !hasNewReference){
					ref.attributerefereced = a
					hasNewReference = true
				}
			}
		]
	}
	
	@Fix(EJSLValidator::AMBIGUOUS_ATTRIBUTE_NAME)
	def attributename(Issue issue, IssueResolutionAcceptor acceptor){
				acceptor.accept(issue, 'Add ID to attribute', 'Change the name.', '') [
			context |
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset+issue.length, 0, "_ID_"+ issue.lineNumber.toString +" " )
			]
	}
	
	@Fix(EJSLValidator::AMBIGUOUS_AUTHOR)
	def uniqueManifestationAuthors(Issue issue, IssueResolutionAcceptor acceptor){
		acceptor.accept(issue, 'Delete this author', 'Delete the name of the author.', '') [
			element, context |
			
			val doubleAuthor = element as Author
			val man = doubleAuthor.eContainer as Manifestation
			man.authors.remove(doubleAuthor)
		]
	}
	
	@Fix(EJSLValidator::AMBIGUOUS_PAGE)
	def pagename(Issue issue, IssueResolutionAcceptor acceptor){
				acceptor.accept(issue, 'Add ID to page', 'Change the name.', '') [
			context |
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset+issue.length, 0, "_ID_"+ issue.lineNumber.toString +" " )
			]
	}
	
	@Fix(EJSLValidator::PAGE_USED_MULTIPLE_TIMES)
	def pageUsedMultipleTimes(Issue issue, IssueResolutionAcceptor acceptor){
				acceptor.accept(issue, 'Remove this page', 'Delete this page.', '') [
			context |
			val doc = context.xtextDocument
			doc.replace((issue.offset - 1), (issue.length+1), " " )
			]
	}
	
	@Fix(EJSLValidator::ENTITY_USED_MULTIPLE_TIMES)
	def entityUsedMultipleTimes(Issue issue, IssueResolutionAcceptor acceptor){
				acceptor.accept(issue, 'Remove this entity', 'Delete this entity.', '') [
			context |
			val doc = context.xtextDocument
			var off = issue.offset
			
			doc.replace((issue.offset), (issue.length), "" )
			deleteUntil(off, ",", doc)
			]
	}
	
	@Fix(EJSLValidator::EXTPACKAGE_CONTAINS_EXTPACKAGE)
	def extpackageContainsExtpackage(Issue issue, IssueResolutionAcceptor acceptor){
				acceptor.accept(issue, 'Remove this Extension package', 'Delete this Extension package.', '') [
			context |
			val doc = context.xtextDocument
			doc.replace((issue.offset), (issue.length), " " )
			]
	}
	
	@Fix(EJSLValidator::AMBIGUOUS_LOCALPARAMETER)
	def localParameter(Issue issue, IssueResolutionAcceptor acceptor){
				acceptor.accept(issue, 'Add ID to Parameter', 'Change the name.', '') [
			context |
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset+issue.length, 0, "_ID_"+ issue.lineNumber.toString +" " )
			]
	}	
	
	def deleteUntil(int off, String searchChar, IXtextDocument doc){
		var offset = off
		var e=true
		while(e){
				var getchar = doc.get((offset -1), 1)
				if(getchar.equals(searchChar)){
					e=false
				}
				doc.replace((offset - 1), (1), "" )
				offset = offset-1
			}
	}
	
	@Fix(EJSLValidator::MORE_THAN_ONE_BACKEND)
	def moreThanOneBackend(Issue issue, IssueResolutionAcceptor acceptor){
				acceptor.accept(issue, 'Remove this Backend', 'Delete this Backend.', '') [
			context |
			val doc = context.xtextDocument
			doc.replace((issue.offset), (issue.length), " " )
			]
	}
	
	@Fix(EJSLValidator::MORE_THAN_ONE_FRONTEND)
	def moreThanOneFronted(Issue issue, IssueResolutionAcceptor acceptor){
				acceptor.accept(issue, 'Remove this Fronted', 'Delete this Fronted.', '') [
			context |
			val doc = context.xtextDocument
			doc.replace((issue.offset), (issue.length), " " )
			]
	}
	
	@Fix(EJSLValidator::AMBIGUOUS_GLOBALPARAMETER)
	def globalParameter(Issue issue, IssueResolutionAcceptor acceptor){
				acceptor.accept(issue, 'Add ID to Parameter', "Change the name of the parameter.", '') [
			context |
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset+issue.length, 0, "_ID_"+ issue.lineNumber.toString +" " )
			]
	}
	
	@Fix(EJSLValidator::AMBIGUOUS_CLASS)
	def className(Issue issue, IssueResolutionAcceptor acceptor){
				acceptor.accept(issue, 'Add ID to Class', "Change the name of the Class.", '') [
			context |
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset+issue.length, 0, "_ID_"+ issue.lineNumber.toString +" " )
			]
	}
	
	@Fix(EJSLValidator::AMBIGUOUS_EXTENSION)
	def extensionName(Issue issue, IssueResolutionAcceptor acceptor){
				acceptor.accept(issue, 'Add ID to extension', "Change the name of the extension.", '') [
			context |
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset+issue.length, 0, "_ID_"+ issue.lineNumber.toString +" " )
			]
	}

	@Fix(EJSLValidator::AMBIGUOUS_KEY)
	def keyValuePairsName(Issue issue, IssueResolutionAcceptor acceptor){
				acceptor.accept(issue, 'Delete Name and give a unique one', "Change the name of the the keyvalue.", '') [
			context |
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset, issue.length, "x_"+ issue.lineNumber.toString +" " )
			]
	}

	@Fix(EJSLValidator::AMBIGUOUS_METHOD)
	def methodeName(Issue issue, IssueResolutionAcceptor acceptor){
				acceptor.accept(issue, 'Add ID to methode', "Change the name of the methode.", '') [
			context |
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset+issue.length, 0, "_ID_"+ issue.lineNumber.toString +" " )
			]
	}
}
