const path = require('path')



module.exports = {
    
    output: {
	
	path: path.join(__dirname, 'public', 'js'),
	
	filename: 'main.js'
	
    },
    
    resolve: {
	
	alias: {
	    
	    'vue': 'vue/dist/vue.common.js'
	    
	}
	
    }
    
};
