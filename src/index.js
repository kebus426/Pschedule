Vue = require('vue')
axios = require('axios')

Vue.component('favorite',{
  props: {
    eventid: {
              type: Number, 
              default: 0,                         
             }
  },
  methods: {
    post: function(){
      console.log(this.eventid)
      
      config = {
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Content-Type': 'application / x-www-form-urlencoded'
        },
        withCredentials: true,
      }
      
      params = new URLSearchParams()
      params.append('eventid',this.eventid)

      url = 'http://118.27.16.67/p-schedule/favorite/new'

      axios.post(url, params, config)
        .then(function (res) {
          //vueにバインドされている値を書き換えると表示に反映され
          console.log(res)
        })
        .catch(function (res) {
          //vueにバインドされている値を書き換えると表示に反映される
          console.log(res)
        })
        
    }    
  },
  template: '<button v-on:click="post">お気に入り</button>'
}
)

new Vue({
  el: '.app',
})
