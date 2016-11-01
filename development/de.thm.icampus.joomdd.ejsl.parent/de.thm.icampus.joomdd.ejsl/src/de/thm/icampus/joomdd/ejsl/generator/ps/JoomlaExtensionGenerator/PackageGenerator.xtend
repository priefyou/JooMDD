/**
 */
package de.thm.icampus.joomdd.ejsl.generator.ps.JoomlaExtensionGenerator

import de.thm.icampus.joomdd.ejsl.eJSL.Component
import de.thm.icampus.joomdd.ejsl.eJSL.ExtensionPackage
import de.thm.icampus.joomdd.ejsl.eJSL.Library
import de.thm.icampus.joomdd.ejsl.eJSL.Module
import de.thm.icampus.joomdd.ejsl.eJSL.Plugin
import de.thm.icampus.joomdd.ejsl.eJSL.Template
import de.thm.icampus.joomdd.ejsl.generator.ps.JoomlaUtil.Slug
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.util.Calendar
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import org.eclipse.xtend.lib.Property
import org.eclipse.xtext.generator.IFileSystemAccess2
import de.thm.icampus.joomdd.ejsl.generator.pi.ExtendedExtension.ExtendedExtensionPackage
import de.thm.icampus.joomdd.ejsl.generator.pi.ExtendedExtension.ExtendedExtensions

public class PackageGenerator extends AbstractExtensionGenerator {
	
	private ExtensionGeneratorClient extClient
	@Property ExtendedExtensionPackage pkg
	String rootPath
	new(ExtendedExtensionPackage pkg, IFileSystemAccess2 access, String path,String rootPath) {
		this.pkg = pkg
		this.fsa = access
		this.name = "pkg_" + Slug.slugify(pkg.name)
		this.path = path
		this.rootPath = rootPath
		
		
	}
	
	override generate() {
		
		// Manifest
		generateFile(path + this.name + ".xml", pkg.xmlContent)
		generateJoomlaDirectory(path + "packages")
		
        // Generate extensions
        for (ext : this.pkg.extensions) {
        	this.extClient = new ExtensionGeneratorClient(fsa, ext, path + "packages/tocompress/", rootPath)
			this.extClient.generateExtension
        }
         compressExtensions(rootPath + "/" +path + "packages/tocompress/" , rootPath + "/"+ path + "packages/")
         var File toDelete = new File(rootPath + "/packages/tocompress")
         toDelete.delete
        
        return ''
	}
	
	def compressExtensions( String fromSrc, String toSrc) {
		
        val byte[] buffer = newByteArrayOfSize(1024)
        for ( ExtendedExtensions ext: pkg.extendedExtensions) {
         
           	try{
           	var File f = null
           	switch(ext.instance){
       		 Component :{ f = new File (fromSrc + ext.extensionName+ "/new/"+ext.extensionName)
       		 	
       		 } 
       		 
       		 default:{
       		 	 f = new File (fromSrc + ext.extensionName)
       		 }
           	}
            var String  zipFilepath =   toSrc + f.name + ".zip";
            println(zipFilepath)
            var FileOutputStream fileOut = new FileOutputStream(zipFilepath)
            var ZipOutputStream zipOut = new ZipOutputStream(fileOut)
            	scanDirectorie(zipOut,buffer,f.getPath(),"" )
            	 zipOut.close();
            	 
            } catch (IOException ioe) {

		        System.out.println("Error creating zip file" + ioe);
		        }
        
        }
       
	}
	
	def CharSequence xmlContent(ExtensionPackage pkg) '''
		<?xml version="1.0" encoding="utf-8"?>
			<extension type="package" version="3.4.0" method="upgrade">
			    <name>«pkg.name»</name>
			    «pkg.manifest.authors.generate»            
			    «IF (pkg.manifest.creationdate != null)»
			    	<creationDate>«pkg.manifest.creationdate»</creationDate>
			    «ELSE»
			    	<creationDate>«Calendar::instance.get(Calendar::YEAR)»</creationDate>
			    «ENDIF»
			    «IF (pkg.manifest.copyright != null)»
			    	<copyright>«pkg.manifest.copyright»</copyright>
			    «ENDIF»
			    «IF (pkg.manifest.license != null)»
			    	<license>GPL 2.0</license>
			    «ENDIF»
			    «IF (pkg.manifest.version != null)»
			    	<version>«pkg.manifest.version»</version>
			    «ENDIF»
			    «IF (pkg.manifest.description != null)»
			    	<description>«pkg.manifest.description»</description>
			    «ENDIF»
			    
				<files folder="packages">
					«FOR com : pkg.extensions.filter(typeof(Component))»
						<file type="component" id="«pkg.name»">«com.name».zip</file>
	                «ENDFOR»
	                «FOR lib : pkg.extensions.filter(typeof(Library))»
	                	<file type="library" id="«pkg.name»">«lib.name».zip</file>
	                «ENDFOR»
	                «FOR mod : pkg.extensions.filter(typeof(Module))»
	                	<file type="module" id="«pkg.name»" client="site">«mod.name».zip</file>
	                «ENDFOR»
	                «FOR tpl : pkg.extensions.filter(typeof(Template))»
						<file type="template" id="«pkg.name»">«tpl.name».zip</file>
	                «ENDFOR»
	                «FOR plg : pkg.extensions.filter(typeof(Plugin))»
						<file type="plugin" id="«pkg.name»" group="«plg.type»">«plg.name».zip</file>
	                «ENDFOR»
				</files>
			</extension>
	'''
	public def void scanDirectorie(ZipOutputStream zos, byte[]buffer, String  src, String path){
		 var File dir = new File(src);

	       var  File[] files = dir.listFiles();
           
	        for (File f : files) {
	           if(! f.isDirectory()){
	           	if(path.isEmpty){
	           		 putFile(zos, f, buffer, "");
	           	}else{
	           		putFile(zos, f, buffer,path);
	          
	           	}
	            }else{
	            		if(path.isEmpty){
	            		    scanDirectorie(zos,buffer,f.getPath(),f.getName() +"/" );
	            			
	            			}
	            		else{	            	
	            			
	            			scanDirectorie(zos,buffer,f.getPath(),path+f.getName() +"/" );}
	            		
	            }
	        }
	}
	public def void putFile( ZipOutputStream zos, File file,byte[] buffer, String root){
		try{
		 var FileInputStream fis = new FileInputStream(file);
         // begin writing a new ZIP entry, positions the stream to the start of the entry data
         zos.putNextEntry(new ZipEntry( root + file.getName()));
	       var  int length;
         while ((length = fis.read(buffer)) > 0) {
             zos.write(buffer, 0, length);
         }
         zos.closeEntry();
         // close the InputStream

         fis.close();
		}catch (IOException ioe) {

	        System.out.println("Error creating zip file" + ioe);

	    }
	}


} // PackageGenerator
