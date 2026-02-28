// 简单脚本：处理图片加载错误，如果图片无法加载则显示占位图
document.addEventListener('DOMContentLoaded', function() {
    const images = document.querySelectorAll('img');
    images.forEach(img => {
        img.onerror = function() {
            this.src = 'https://via.placeholder.com/400x500?text=ASSODA+Image';
            console.log('图片加载失败，已切换占位图：' + this.src);
        };
    });
});

