package com.fueltracker.fuel_tracker_app.ui.drawer

import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.ripple.rememberRipple
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.GridView

private val SelectedBackground = Color(0xFFF2F2F2)
private val TextPrimary = Color(0xFF333333)
private val TextSecondary = Color(0xFF64748B)
private val PrimaryBlue = Color(0xFF0066CC)

@Composable
fun AccountDrawerMenuItem(
    icon: ImageVector,
    title: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val backgroundColor = if (selected) SelectedBackground else Color.Transparent
    val iconTint = if (selected) PrimaryBlue else TextSecondary
    val fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Medium

    Surface(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 0.dp, vertical = 2.dp),
        shape = RoundedCornerShape(12.dp),
        color = backgroundColor,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp)
                .clickable(
                    role = Role.Button,
                    interactionSource = remember { MutableInteractionSource() },
                    indication = rememberRipple(bounded = true),
                    onClick = onClick,
                )
                .padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = iconTint,
                modifier = Modifier.size(24.dp),
            )
            Spacer(modifier = Modifier.width(16.dp))
            Text(
                text = title,
                fontSize = 16.sp,
                fontWeight = fontWeight,
                color = TextPrimary,
                lineHeight = 20.sp,
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun AccountDrawerMenuItemPreview() {
    MaterialTheme {
        ColumnPreview()
    }
}

@Composable
private fun ColumnPreview() {
    androidx.compose.foundation.layout.Column {
        AccountDrawerMenuItem(
            icon = Icons.Default.GridView,
            title = "List Grid Card",
            selected = true,
            onClick = {},
        )
        AccountDrawerMenuItem(
            icon = Icons.Default.GridView,
            title = "Cài đặt",
            selected = false,
            onClick = {},
        )
    }
}
